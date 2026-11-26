[CmdletBinding()]
param([switch]$Help)

. (Join-Path $PSScriptRoot 'powershell-bootstrap.ps1')
$bootstrap = Initialize-WorkshopScript -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters -RemainingArguments $args -DotSourced ($MyInvocation.InvocationName -eq '.')
if ($bootstrap.Handled) { exit $bootstrap.Code }

$script:WorkshopNodeMinimum = [version]'24.0.0'
$script:WorkshopNodeMajor = 24
$script:WorkshopNvmMajor = 2
$script:CheckFailures = 0
$script:CheckContext = 'Windows PowerShell 7'

function Invoke-ToolProbe {
    param([string]$Name, [string[]]$Arguments = @())
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ Code = 127; Text = "$Name not found" }
    }
    try {
        $global:LASTEXITCODE = 0
        $output = & $Name @Arguments 2>&1 | Out-String
        return [pscustomobject]@{ Code = $LASTEXITCODE; Text = $output.Trim() }
    }
    catch {
        return [pscustomobject]@{ Code = 1; Text = $_.Exception.Message }
    }
}

function Add-Check {
    param([string]$Status, [string]$Id, [string]$Message)
    Write-WorkshopMessage "[$Status] [$script:CheckContext] ${Id}: $Message"
    if ($Status -eq 'FAIL') { $script:CheckFailures++ }
}

function Write-CheckGroup {
    param([string]$Name)
    Write-WorkshopMessage "[INFO] == $Name =="
}

function Get-ToolVersion {
    param([string]$Text)
    if ($Text -match '(\d+\.\d+(\.\d+)?)') { return [version]$Matches[1] }
}

function Test-MinimumVersion {
    param([string]$Id, [version]$Minimum, [string]$Name, [string[]]$Arguments)
    $probe = Invoke-ToolProbe $Name $Arguments
    if ($probe.Code -ne 0) { Add-Check FAIL $Id $probe.Text; return }
    $version = Get-ToolVersion $probe.Text
    if (-not $version) { Add-Check FAIL $Id "Could not read the version: $(($probe.Text -split "`n")[0])"; return }
    if ($version -ge $Minimum) { Add-Check PASS $Id "$version (>= $Minimum)"; return $version }
    Add-Check FAIL $Id "$version (requires >= $Minimum)"
}

function Update-ProcessPath {
    $paths = foreach ($scope in @('Machine', 'User')) { [Environment]::GetEnvironmentVariable('Path', $scope) }
    $env:Path = (($paths + ($env:Path -split ';')) | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Test-WorkshopHost {
    Write-CheckGroup 'Host'
    $build = [Environment]::OSVersion.Version.Build
    if ($build -ge 22000) { Add-Check PASS windows "Windows 11 (build $build)" }
    else { Add-Check FAIL windows "Build $build (requires Windows 11)" }
    $arch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    if ($arch -eq [Runtime.InteropServices.Architecture]::X64) { Add-Check PASS architecture 'x64' }
    else { Add-Check FAIL architecture "$arch (requires 64-bit Intel or AMD)" }
    if ($PSVersionTable.PSVersion.Major -ge 7) { Add-Check PASS powershell7 "$($PSVersionTable.PSVersion)" }
    else { Add-Check FAIL powershell7 "$($PSVersionTable.PSVersion) (requires PowerShell 7)" }
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -ErrorAction Stop
        if ($feature.State -eq 'Enabled') { Add-Check PASS hypervisor-platform 'Enabled' }
        else { Add-Check FAIL hypervisor-platform "$($feature.State). In an elevated PowerShell, run: Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All" }
    }
    catch {
        Add-Check MANUAL hypervisor-platform 'Could not query without elevation. Confirm Windows Hypervisor Platform is enabled.'
    }
}

function Test-WorkshopCoreTools {
    Write-CheckGroup 'Core tools'
    $null = Test-MinimumVersion git ([version]'2.0.0') git @('--version')
    $null = Test-MinimumVersion gh ([version]'2.0.0') gh @('--version')
    Add-Check MANUAL gh-auth 'Run gh auth status and confirm you are signed in to your personal GitHub account.'
    $nvm = Invoke-ToolProbe nvm @('version')
    $nvmVersion = if ($nvm.Code -eq 0) { Get-ToolVersion $nvm.Text }
    if ($nvmVersion -and $nvmVersion.Major -eq $script:WorkshopNvmMajor) { Add-Check PASS nvm-windows "$nvmVersion" }
    elseif ($nvmVersion) { Add-Check FAIL nvm-windows "$nvmVersion (requires nvm-windows $script:WorkshopNvmMajor.x)" }
    else { Add-Check FAIL nvm-windows "Not found. The workshop installs Node.js through nvm-windows $script:WorkshopNvmMajor.x." }
    $node = Test-MinimumVersion node $script:WorkshopNodeMinimum node @('--version')
    if (-not $node) {
        Add-Check INFO node-install "Run ./scripts/install-prerequisites.ps1 to install the latest Node.js $script:WorkshopNodeMajor.x with nvm-windows."
    }
    $npm = Invoke-ToolProbe npm @('--version')
    if ($npm.Code -eq 0) { Add-Check PASS npm $npm.Text } else { Add-Check FAIL npm $npm.Text }
}

function Test-WorkshopCopilot {
    Write-CheckGroup 'GitHub Copilot CLI'
    $probe = Invoke-ToolProbe copilot @('--version')
    if ($probe.Code -eq 0) { Add-Check PASS copilot "$(Get-ToolVersion $probe.Text)" } else { Add-Check FAIL copilot $probe.Text }
    Add-Check MANUAL copilot-auth 'Confirm the Copilot license and sign in with /login in copilot, or prepare a fine-grained PAT with Copilot Requests.'
}

function Test-WorkshopDockerSandboxes {
    Write-CheckGroup 'Docker Sandboxes'
    $null = Test-MinimumVersion sbx ([version]'0.45.0') sbx @('--version')
    Add-Check MANUAL sbx-auth 'Run sbx login, then store the Copilot token with sbx secret set copilot.'
}

function Test-WorkshopAzure {
    Write-CheckGroup 'Azure Container Apps Sandboxes'
    $saved = $env:AZURE_EXTENSION_USE_DYNAMIC_INSTALL
    $env:AZURE_EXTENSION_USE_DYNAMIC_INSTALL = 'no'
    try {
        if (Test-MinimumVersion az ([version]'2.0.0') az @('--version')) {
            $state = Invoke-ToolProbe az @('account', 'show', '--query', 'state', '--output', 'tsv')
            if ($state.Code -eq 0 -and $state.Text -eq 'Enabled') { Add-Check PASS az-login 'Signed in with an enabled subscription' }
            else { Add-Check FAIL az-login "Run az login and select the workshop subscription (exit code $($state.Code))." }
        }
    }
    finally { $env:AZURE_EXTENSION_USE_DYNAMIC_INSTALL = $saved }
    $aca = Invoke-ToolProbe aca @('--version')
    if ($aca.Code -eq 0) { Add-Check PASS aca "$(Get-ToolVersion $aca.Text)" } else { Add-Check FAIL aca $aca.Text }
    Add-Check MANUAL aca-config 'Run aca doctor and aca config show. Confirm the sandbox group, region, and RBAC.'
}

function Test-WorkshopOptional {
    Write-CheckGroup 'Optional (180-minute extension)'
    $docker = Invoke-ToolProbe docker @('--version')
    if ($docker.Code -eq 0) { Add-Check PASS docker "$(Get-ToolVersion $docker.Text)" }
    else { Add-Check WARN docker 'Not found. Required only to build the custom mixin in the 180-minute extension.' }
    $buildx = Invoke-ToolProbe docker @('buildx', 'version')
    if ($buildx.Code -eq 0) { Add-Check PASS buildx "$(Get-ToolVersion $buildx.Text)" }
    else { Add-Check WARN buildx 'Not found. Required only to build the custom mixin in the 180-minute extension.' }
    Add-Check INFO docker-note 'Docker Desktop and az containerapp do not replace sbx or aca.'
}

function Invoke-PrerequisiteMain {
    param([switch]$Help)
    if ($Help) { Write-Host './scripts/check-prerequisites.ps1'; return 0 }
    $script:CheckFailures = 0
    Update-ProcessPath
    Test-WorkshopHost
    Test-WorkshopCoreTools
    Test-WorkshopCopilot
    Test-WorkshopAzure
    Test-WorkshopDockerSandboxes
    Test-WorkshopOptional
    Write-Host ''
    Write-Host "Required failures: $script:CheckFailures. MANUAL items were not checked automatically."
    if ($script:CheckFailures -eq 0) { return 0 }
    return 1
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-PrerequisiteMain -Help:$Help)
}
