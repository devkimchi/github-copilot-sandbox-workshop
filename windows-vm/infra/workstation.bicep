// appmod-box의 구성을 참고해 워크숍용으로 수정했다. 고지: ../LICENSE-UPSTREAM
targetScope = 'resourceGroup'

param location string
param token string
param tags object
param adminUsername string
@secure()
param adminPassword string
param confirmWindowsClientLicense string
param vmSize string
param imageSku string
param imageVersion string

var stageScript = replace(
  loadTextContent('../scripts/stage-tools.ps1'),
  '__INSTALLER_BASE64__',
  base64(loadTextContent('../scripts/install-tools.ps1'))
)

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-01-01' = {
  name: 'nsg-${token}'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource natIp 'Microsoft.Network/publicIPAddresses@2025-01-01' = {
  name: 'pip-nat-${token}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource nat 'Microsoft.Network/natGateways@2025-01-01' = {
  name: 'nat-${token}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      { id: natIp.id }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: 'vnet-${token}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.40.0.0/16']
    }
    subnets: [
      {
        name: 'workstation'
        properties: {
          addressPrefix: '10.40.0.0/24'
          defaultOutboundAccess: false
          networkSecurityGroup: { id: nsg.id }
          natGateway: { id: nat.id }
        }
      }
    ]
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2025-01-01' = {
  name: 'bas-${token}'
  location: location
  tags: tags
  sku: {
    name: 'Developer'
  }
  properties: {
    scaleUnits: 2
    ipConfigurations: []
    virtualNetwork: { id: vnet.id }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2025-01-01' = {
  name: 'nic-${token}'
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'private'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'workstation')
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: 'vm-${token}'
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: vmSize }
    licenseType: confirmWindowsClientLicense == 'true' ? 'Windows_Client' : null
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: 256
        managedDisk: { storageAccountType: 'Premium_LRS' }
      }
    }
    osProfile: {
      computerName: take('ws-${token}', 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        timeZone: 'Korea Standard Time'
      }
    }
    networkProfile: {
      networkInterfaces: [{ id: nic.id }]
    }
    diagnosticsProfile: {
      bootDiagnostics: { enabled: true }
    }
  }
}

resource delivery 'Microsoft.Compute/virtualMachines/runCommands@2025-04-01' = {
  parent: vm
  name: 'stage-workshop-tools'
  location: location
  tags: tags
  properties: {
    source: { script: stageScript }
    asyncExecution: false
    timeoutInSeconds: 300
    treatFailureAsDeploymentFailure: true
  }
}

resource shutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vm.name}'
  location: location
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: { time: '0000' }
    timeZoneId: 'Korea Standard Time'
    targetResourceId: vm.id
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
  }
}

output vmName string = vm.name
output vmId string = vm.id
output bastionName string = bastion.name
