targetScope = 'subscription'

@minLength(1)
@maxLength(32)
param environmentName string

@metadata({
  azd: {
    type: 'location'
  }
})
param location string

@minLength(1)
@maxLength(20)
param adminUsername string = 'workshopuser'

@secure()
@minLength(12)
@maxLength(123)
@description('VM 관리자 암호. azd의 보안 입력을 사용하고 파일이나 로그에 저장하지 않는다.')
param adminPassword string

@allowed([
  'true'
])
@description('Windows 클라이언트 Azure 라이선스 자격을 본인이 확인한 경우에만 true로 지정한다.')
param confirmWindowsClientLicense string

param vmSize string = 'Standard_D8s_v5'
param imageSku string = 'win11-26h2-ent'

@description('Windows VM 이미지 버전. 기본값은 latest이며 고정 숫자 버전도 지정할 수 있다.')
param imageVersion string = 'latest'

var token = uniqueString(subscription().id, environmentName, location)
var tags = {
  'azd-env-name': environmentName
  workload: 'copilot-sandbox-workshop'
}

resource group 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${environmentName}-vm'
  location: location
  tags: tags
}

module workstation 'workstation.bicep' = {
  name: 'workstation'
  scope: group
  params: {
    location: location
    token: token
    tags: tags
    adminUsername: adminUsername
    adminPassword: adminPassword
    confirmWindowsClientLicense: confirmWindowsClientLicense
    vmSize: vmSize
    imageSku: imageSku
    imageVersion: imageVersion
  }
}

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = group.name
output AZURE_VM_NAME string = workstation.outputs.vmName
output AZURE_VM_ID string = workstation.outputs.vmId
output AZURE_VM_ADMIN_USERNAME string = adminUsername
output AZURE_BASTION_NAME string = workstation.outputs.bastionName
output WORKSHOP_TOOL_HELPER string = 'C:\\WorkshopSetup\\install-tools.ps1'
