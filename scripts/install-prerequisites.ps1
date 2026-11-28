[CmdletBinding()]
param([switch]$Help)

. (Join-Path $PSScriptRoot 'powershell-bootstrap.ps1')
$bootstrap = Initialize-WorkshopScript -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters -RemainingArguments $args -DotSourced ($MyInvocation.InvocationName -eq '.') -AllowInstall
if ($bootstrap.Handled) { exit $bootstrap.Code }

. (Join-Path $PSScriptRoot 'check-prerequisites.ps1') -Help:$Help

$script:CheckContext = 'Windows host'

function Confirm-ToolInstall {
    param([string]$Message)
    if (-not (Test-WorkshopBootstrapInteractive) -or $Host.Name -ne 'ConsoleHost') { return $false }
    Write-Host $Message
    return (Read-Host 'Continue? [y/N]') -cmatch '^[yY]$'
}

function Test-Winget {
    if (Get-Command winget -CommandType Application -ErrorAction SilentlyContinue) { return $true }
    Write-WorkshopMessage '[MANUAL] Windows Package Manager (winget) is required for automatic installation.'
    return $false
}

function Install-WingetPackage {
    param([string]$Name, [string]$Package)
    if (-not (Test-Winget)) { return $false }
    if (-not (Confirm-ToolInstall "${Name}: Install the winget package $Package. Network access and administrator approval may be required. Review the terms shown by winget.")) { return $true }
    & winget install --id $Package --exact --source winget | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-WorkshopMessage "[FAIL] $Name installation failed (exit code $LASTEXITCODE)."
        return $false
    }
    Update-ProcessPath
    return $true
}

function Get-WorkshopNodeRelease {
    param([int]$Major)
    $releases = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -TimeoutSec 30 -ErrorAction Stop
    return @($releases | Where-Object { $_.version -match "^v$Major\.\d+\.\d+$" } |
        ForEach-Object { [version]$_.version.TrimStart('v') } | Sort-Object -Descending | Select-Object -First 1)[0]
}

function Get-WorkshopNvmConfiguration {
    $probe = Invoke-ToolProbe nvm @('config', 'get', 'root', 'auto_install', '--json')
    if ($probe.Code -ne 0) { Write-WorkshopMessage "[FAIL] Could not read the nvm-windows configuration: $($probe.Text)"; return }
    try { return $probe.Text | ConvertFrom-Json -ErrorAction Stop }
    catch { Write-WorkshopMessage '[FAIL] Could not parse the nvm-windows configuration.' }
}

function Install-WorkshopNvm {
    $nvm = Get-Command nvm -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $nvm) {
        $node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($node) {
            Write-WorkshopMessage "[MANUAL] Node.js is already installed outside nvm-windows ($($node.Source)). Uninstall it with its original installer, then rerun this script."
            return $false
        }
        if (-not (Install-WingetPackage 'nvm-windows' 'AuthorSoftware.NVMWindows')) { return $false }
        if (-not (Get-Command nvm -CommandType Application -ErrorAction SilentlyContinue)) {
            Write-WorkshopMessage '[WARN] nvm-windows was not installed. Node.js will not be installed.'
            return $false
        }
    }
    $version = Get-ToolVersion (Invoke-ToolProbe nvm @('version')).Text
    if (-not $version -or $version.Major -ne $script:WorkshopNvmMajor) {
        Write-WorkshopMessage "[MANUAL] nvm-windows $version is installed. Upgrade to nvm-windows $script:WorkshopNvmMajor.x, then rerun this script."
        return $false
    }
    Write-WorkshopMessage "[INFO] nvm-windows: $version"
    return $true
}

function Install-WorkshopNode {
    if (-not (Install-WorkshopNvm)) { return $false }
    $config = Get-WorkshopNvmConfiguration
    if (-not $config -or -not $config.root) { return $false }
    try { $latest = Get-WorkshopNodeRelease $script:WorkshopNodeMajor }
    catch { Write-WorkshopMessage "[FAIL] Could not query Node.js releases: $($_.Exception.Message)"; return $false }
    if (-not $latest -or $latest.Major -ne $script:WorkshopNodeMajor) {
        Write-WorkshopMessage "[FAIL] Could not find a stable Node.js $script:WorkshopNodeMajor.x release."
        return $false
    }
    $installedNode = Join-Path $config.root "v$latest\node.exe"
    if (Test-Path -LiteralPath $installedNode -PathType Leaf) {
        Write-WorkshopMessage "[INFO] node: v$latest is already installed with nvm-windows."
    }
    else {
        if (-not (Confirm-ToolInstall "Node.js: Install v$latest (latest $script:WorkshopNodeMajor.x) with nvm-windows. Existing versions will be preserved. Network access is required.")) {
            Write-WorkshopMessage '[WARN] Node.js installation was not approved.'
            return $true
        }
        & nvm install "$latest" | Out-Host
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $installedNode -PathType Leaf)) {
            Write-WorkshopMessage '[FAIL] Node.js installation failed.'
            return $false
        }
    }
    if ((Get-ToolVersion (Invoke-ToolProbe node @('--version')).Text) -ne $latest) {
        if (-not (Confirm-ToolInstall "Node.js: Run nvm use $latest to set the default Node.js version for subsequent terminals.")) {
            Write-WorkshopMessage "[INFO] Not activated. Run nvm use $latest manually if needed."
            return $true
        }
        & nvm use "$latest" | Out-Host
        Update-ProcessPath
    }
    if ((Get-ToolVersion (Invoke-ToolProbe node @('--version')).Text) -ne $latest -or (Invoke-ToolProbe npm @('--version')).Code -ne 0) {
        Write-WorkshopMessage '[FAIL] Could not verify the active Node.js or npm. Check PATH and nvm list in a new terminal.'
        return $false
    }
    Write-WorkshopMessage "[PASS] [$script:CheckContext] Node.js $latest is active through nvm-windows."
    return $true
}

function Install-AcaCli {
    if (-not (Confirm-ToolInstall 'Azure Container Apps CLI: Run the official installer for the current user. It verifies the SHA-256 of the archive. Network access is required. Source: https://aka.ms/aca-cli-install-ps')) { return $true }
    $directory = Join-Path ([IO.Path]::GetTempPath()) "workshop-installer-$([guid]::NewGuid().ToString('N'))"
    $installer = Join-Path $directory 'install.ps1'
    try {
        $null = New-Item -ItemType Directory -Path $directory
        Invoke-WebRequest -Uri 'https://aka.ms/aca-cli-install-ps' -OutFile $installer -UseBasicParsing -ErrorAction Stop
        & $installer
        Update-ProcessPath
        if (-not (Get-Command aca -ErrorAction SilentlyContinue)) {
            $default = Join-Path $env:USERPROFILE '.aca\bin'
            if (Test-Path -LiteralPath (Join-Path $default 'aca.exe')) {
                $env:Path = "$default;$env:Path"
                Write-WorkshopMessage "[MANUAL] Open a new terminal or add $default to PATH."
            }
        }
        return $true
    }
    catch {
        Write-WorkshopMessage "[FAIL] Azure Container Apps CLI installation failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        Remove-Item -LiteralPath $directory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-WindowsTools {
    $failed = $false
    $toolGroups = @(
        @{
            Name = 'Core tools'
            Tools = @(
                @{ Name = 'git'; Command = 'git'; Package = 'Git.Git' },
                @{ Name = 'gh'; Command = 'gh'; Package = 'GitHub.cli' },
                @{ Name = 'node'; Command = $null }
            )
        },
        @{
            Name = 'GitHub Copilot CLI'
            Tools = @(
                @{ Name = 'copilot'; Command = 'copilot'; Package = 'GitHub.Copilot' }
            )
        },
        @{
            Name = 'Azure Container Apps Sandboxes'
            Tools = @(
                @{ Name = 'az'; Command = 'az'; Package = 'Microsoft.AzureCLI' },
                @{ Name = 'aca'; Command = 'aca'; Package = $null }
            )
        },
        @{
            Name = 'Docker Sandboxes'
            Tools = @(
                @{ Name = 'sbx'; Command = 'sbx'; Package = 'Docker.sbx' }
            )
        }
    )
    foreach ($group in $toolGroups) {
        Write-CheckGroup $group.Name
        foreach ($tool in $group.Tools) {
            if ($tool.Name -eq 'node') {
                if (-not (Install-WorkshopNode)) { $failed = $true }
                continue
            }
            $existing = Get-Command $tool.Command -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($existing) {
                Write-WorkshopMessage "[INFO] $($tool.Name): Found on PATH ($($existing.Source)). It will not be installed or updated."
                continue
            }
            $ok = if ($tool.Package) { Install-WingetPackage $tool.Name $tool.Package } else { Install-AcaCli }
            if (-not $ok) { $failed = $true }
        }
    }
    Write-CheckGroup 'Host features'
    Write-WorkshopMessage '[MANUAL] If Windows Hypervisor Platform is disabled, run this in an elevated PowerShell and restart: Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All'
    return (-not $failed)
}

function Initialize-AzureLogin {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) { return $true }
    Write-CheckGroup 'Azure sign-in'
    $env:AZURE_EXTENSION_USE_DYNAMIC_INSTALL = 'no'
    $account = Invoke-ToolProbe az @('account', 'show', '--query', 'state', '--output', 'tsv')
    if ($account.Code -eq 0 -and $account.Text -eq 'Enabled') {
        Write-WorkshopMessage '[INFO] az: Already signed in with an enabled subscription.'
        return $true
    }
    if (Confirm-ToolInstall 'Azure CLI: Run az login in this terminal. A browser window may open.') {
        & az login | Out-Host
        if ($LASTEXITCODE -ne 0) { Write-WorkshopMessage '[FAIL] az login failed.'; return $false }
    }
    return $true
}

function Invoke-InstallPrerequisiteMain {
    if ($Help) { Write-Host './scripts/install-prerequisites.ps1'; return 0 }
    if (-not (Test-WorkshopBootstrapInteractive)) {
        Write-WorkshopMessage '[FAIL] Installation requires an interactive terminal. Nothing will be installed in a noninteractive session.'
        return 1
    }
    Write-Host "Installation target: Windows host. Tools already on PATH will not be changed; Node.js $script:WorkshopNodeMajor.x is installed with nvm-windows $script:WorkshopNvmMajor.x."
    Update-ProcessPath
    $installed = Install-WindowsTools
    $prepared = Initialize-AzureLogin
    Write-WorkshopMessage '[INFO] Running read-only prerequisite checks from ./scripts/check-prerequisites.ps1. Verify MANUAL items yourself.'
    $script:CheckContext = 'Windows PowerShell 7'
    $result = Invoke-PrerequisiteMain
    if (-not $installed -or -not $prepared -or $result -ne 0) { return 1 }
    return 0
}

if ($MyInvocation.InvocationName -ne '.') { exit (Invoke-InstallPrerequisiteMain) }
