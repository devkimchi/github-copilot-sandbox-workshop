#requires -Version 5.1
#requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$EnableHypervisorPlatform,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

function Test-StatusOutputTerminal {
    return -not [Console]::IsOutputRedirected
}

function Write-Status {
    param(
        [ValidateSet('INFO', 'PASS', 'WARNING', 'FAIL')][string]$Level,
        [string]$Message
    )
    if ($Level -eq 'WARNING') {
        Write-Warning $Message
        return
    }
    $options = @{}
    if (-not $env:NO_COLOR -and -not $env:CI -and $env:TERM -ne 'dumb' -and (Test-StatusOutputTerminal)) {
        $options.ForegroundColor = switch ($Level) {
            'INFO' { 'Cyan' }
            'PASS' { 'Green' }
            'FAIL' { 'Red' }
        }
    }
    Write-Host "[$Level] $Message" @options
}

trap {
    Write-Status -Level FAIL -Message $_.Exception.Message
    break
}

if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    throw 'SYSTEM이 아닌 실제 로그인한 관리자 사용자로 실행하세요.'
}
Get-Command winget.exe -ErrorAction Stop | Out-Null
$dockerSandboxSteps = @(
    if ($EnableHypervisorPlatform) {
        @{ Kind = 'hypervisor'; Description = 'Windows Hypervisor Platform 활성화. 재부팅이 필요할 수 있음' }
    }
    @{ Kind = 'winget'; Id = 'Docker.sbx'; Command = 'sbx.exe' }
)
$toolGroups = @(
    @{
        Name = '공통 개발 환경'
        Steps = @(
            @{ Kind = 'winget'; Id = 'Git.Git'; Command = 'git.exe' },
            @{ Kind = 'winget'; Id = 'GitHub.cli'; Command = 'gh.exe' },
            @{ Kind = 'winget'; Id = 'AuthorSoftware.NVMWindows'; Command = 'nvm.exe' },
            @{ Kind = 'winget'; Id = 'Microsoft.PowerShell'; Command = 'pwsh.exe' },
            @{ Kind = 'node'; Description = 'Node.js: nvm-windows 2.x를 통해 24.x 최신 버전 설치' }
        )
    },
    @{
        Name = 'Copilot CLI 샌드박스'
        Steps = @(
            @{ Kind = 'winget'; Id = 'GitHub.Copilot'; Command = 'copilot.exe' }
        )
    },
    @{
        Name = 'Azure Container Apps Sandboxes'
        Steps = @(
            @{ Kind = 'winget'; Id = 'Microsoft.AzureCLI'; Command = 'az.cmd' },
            @{ Kind = 'aca'; Description = 'ACA CLI: 공식 설치 스크립트 https://aka.ms/aca-cli-install-ps 사용' }
        )
    },
    @{
        Name = 'Docker Sandboxes'
        Steps = $dockerSandboxSteps
    },
    @{
        Name = 'Docker Desktop 및 Linux 개발 환경'
        Steps = @(
            @{ Kind = 'wsl'; Description = 'WSL2와 Ubuntu: wsl --install 사용. 재부팅과 Ubuntu 첫 실행 시 사용자 생성이 필요할 수 있음' },
            @{ Kind = 'winget'; Id = 'Docker.DockerDesktop'; Command = 'docker.exe' }
        )
    }
)
$existingNode = Get-Command node.exe -ErrorAction SilentlyContinue
if ($existingNode -and -not (Get-Command nvm.exe -ErrorAction SilentlyContinue)) {
    throw "nvm-windows 밖에서 설치한 Node.js가 있습니다($($existingNode.Source)). 원래 설치 프로그램으로 제거한 뒤 다시 실행하세요."
}
Write-Status -Level INFO -Message '설치 대상과 순서:'
foreach ($group in $toolGroups) {
    Write-Status -Level INFO -Message "[$($group.Name)]"
    foreach ($step in $group.Steps) {
        $description = if ($step.Kind -eq 'winget') {
            "$($step.Id): WinGet에서 제공하는 최신 버전"
        }
        else {
            $step.Description
        }
        Write-Status -Level INFO -Message "  $description"
    }
}
if ($Yes) {
    Write-Status -Level INFO -Message '-Yes 옵션으로 설치와 패키지 사용 조건에 동의한 것으로 간주합니다.'
}
else {
    $answer = Read-Host '설치와 표시한 패키지 사용 조건을 검토한 뒤 INSTALL을 입력하세요'
    if ($answer -cne 'INSTALL') { throw '사용자가 도구 설치를 취소했습니다.' }
}
function Get-UbuntuWslVersion {
    $previousWslUtf8 = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $ErrorActionPreference = 'Continue'
        $lines = @(& wsl.exe --list --verbose 2>&1 | ForEach-Object { "$_" })
        $exitCode = $LASTEXITCODE
        $version = $null
        foreach ($line in $lines) {
            $fields = @(($line -replace '^\s*\*', '').Trim() -split '\s+')
            if ($fields.Count -ge 3 -and $fields[0] -eq 'Ubuntu') {
                if ($fields[-1] -notmatch '^\d+$') { throw "Ubuntu의 WSL 버전을 읽지 못했습니다: $line" }
                $version = [int]$fields[-1]
                break
            }
        }
        return [pscustomobject]@{ Version = $version; ExitCode = $exitCode; Output = ($lines -join [Environment]::NewLine) }
    }
    finally {
        $env:WSL_UTF8 = $previousWslUtf8
    }
}

function Get-WslFeatures {
    foreach ($name in @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')) {
        Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction Stop
    }
}

function Test-WslRestartPending {
    param([array]$Features)
    return @($Features | Where-Object { $_.State.ToString() -in @('EnablePending', 'DisablePending') }).Count -gt 0
}

function Test-WslRestartNeededAfterInstall {
    param([array]$Features)
    if (Test-WslRestartPending $Features) { return $true }
    return @($Features | Where-Object {
        $_.FeatureName -eq 'VirtualMachinePlatform' -and $_.State.ToString() -eq 'Enabled'
    }).Count -eq 0
}

function Invoke-WslInstall {
    param([string[]]$Arguments)
    $previousWslUtf8 = $env:WSL_UTF8
    $previousEncoding = [Console]::OutputEncoding
    $env:WSL_UTF8 = '1'
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    try {
        $ErrorActionPreference = 'Continue'
        $lines = @(& wsl.exe @Arguments 2>&1 | ForEach-Object { "$_" -replace "`0", '' })
        $exitCode = $LASTEXITCODE
        $lines | ForEach-Object { Write-Host $_ }
        return [pscustomobject]@{ ExitCode = $exitCode; Output = ($lines -join ' ') }
    }
    finally {
        [Console]::OutputEncoding = $previousEncoding
        $env:WSL_UTF8 = $previousWslUtf8
    }
}

function Test-WslInstallRestartRequired {
    param($Result)
    if ($Result.ExitCode -in @(1641, 3010)) { return $true }
    if ($Result.ExitCode -ne 0) { return $false }
    # WSL 3.x can print the localized Windows 3010 message but return exit 0.
    $message = (New-Object System.ComponentModel.Win32Exception(3010)).Message
    $message = ($message -replace '\s+', ' ').Trim()
    $output = ($Result.Output -replace '\s+', ' ').Trim()
    return $message.Length -gt 0 -and $output.IndexOf($message, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Write-WslRestartRequired {
    Write-Status -Level WARNING -Message 'WSL 구성 요소에 재부팅이 필요합니다. Windows를 재부팅한 뒤 이 스크립트를 다시 실행하세요. 재부팅 후에도 같은 메시지가 반복되면 wsl.exe --status와 Windows 기능 상태를 확인하세요. Ubuntu 또는 Docker Desktop 설치가 아직 완료되지 않았을 수 있습니다.'
}

function Test-NoWslDistribution {
    param([string]$Output)
    return $Output -match 'WSL_E_DEFAULT_DISTRO_NOT_FOUND|no installed distributions'
}

function Test-UbuntuPackageInstalled {
    if (Get-Command ubuntu.exe -CommandType Application -ErrorAction SilentlyContinue) { return $true }
    return $null -ne (Get-AppxPackage -Name 'CanonicalGroupLimited.Ubuntu' -ErrorAction SilentlyContinue)
}

function Write-UbuntuFirstLaunchRequired {
    Write-Status -Level WARNING -Message 'Ubuntu 패키지는 설치됐지만 WSL 배포판으로 등록되지 않았습니다. 시작 메뉴에서 Ubuntu를 열거나 새 PowerShell 창에서 ubuntu.exe를 실행해 Linux 사용자 이름과 암호를 만드세요. exit로 Ubuntu를 닫은 뒤 이 스크립트를 다시 실행하세요. Docker Desktop 설치는 아직 진행하지 않았습니다.'
}

function Install-WingetPackage {
    param([hashtable]$Package)
    if (Get-Command $package.Command -ErrorAction SilentlyContinue) {
        Write-Status -Level WARNING -Message "$($package.Command)이 이미 있습니다. 변경하지 않습니다. 최신 버전이 필요한 경우 원래 설치 경로로 직접 업데이트하세요."
        return
    }
    Write-Status -Level INFO -Message "$($package.Id) 설치를 시작합니다."
    & winget.exe install --id $package.Id --exact --source winget --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "패키지 설치 실패: $($package.Id), exit=$LASTEXITCODE" }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
    Write-Status -Level PASS -Message "$($package.Id) 설치 명령을 완료했습니다."
}

function Install-Node {
    Write-Status -Level INFO -Message 'Node.js 설치와 버전 확인을 시작합니다.'
    $actualNvm = & nvm.exe version
    if ($LASTEXITCODE -ne 0 -or $actualNvm -notmatch '^v?2\.') {
        throw "nvm-windows 2.x가 필요합니다. 현재 버전: $actualNvm"
    }
    $releases = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -TimeoutSec 30 -ErrorAction Stop
    $latestNode = $releases | Where-Object { $_.version -match '^v24\.\d+\.\d+$' } |
        ForEach-Object { [version]$_.version.TrimStart('v') } | Sort-Object -Descending | Select-Object -First 1
    if (-not $latestNode) { throw 'Node.js 24.x 최신 버전을 조회하지 못했습니다.' }
    $NodeVersion = $latestNode.ToString()
    & nvm.exe install $NodeVersion
    if ($LASTEXITCODE -ne 0) { throw "Node.js $NodeVersion 설치 실패, exit=$LASTEXITCODE" }
    & nvm.exe use $NodeVersion
    if ($LASTEXITCODE -ne 0) { throw "Node.js $NodeVersion 선택 실패, exit=$LASTEXITCODE" }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
    $npm = Get-Command npm -CommandType Application -ErrorAction Stop | Select-Object -First 1
    & $npm --version
    if ($LASTEXITCODE -ne 0) { throw "npm 실행 실패, exit=$LASTEXITCODE" }
    $actualNode = & node.exe --version
    if ($LASTEXITCODE -ne 0 -or $actualNode -ne "v$NodeVersion") {
        throw "실제 Node.js 버전($actualNode)이 요청한 $NodeVersion과 다릅니다."
    }
    Write-Status -Level PASS -Message "Node.js $NodeVersion 활성 버전을 확인했습니다."
}

function Install-AcaCli {
    if (Get-Command aca -ErrorAction SilentlyContinue) {
        Write-Status -Level WARNING -Message '기존 ACA CLI를 보존합니다. 최신 버전이 필요한 경우 원래 설치 경로로 직접 업데이트하세요.'
        return
    }
    Write-Status -Level INFO -Message 'ACA CLI 설치를 시작합니다.'
    $installerDirectory = Join-Path ([IO.Path]::GetTempPath()) "workshop-aca-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $installerDirectory -ErrorAction Stop | Out-Null
    $installer = Join-Path $installerDirectory 'install.ps1'
    try {
        Invoke-WebRequest -Uri 'https://aka.ms/aca-cli-install-ps' -OutFile $installer -UseBasicParsing -ErrorAction Stop
        & pwsh.exe -NoProfile -File $installer
        if ($LASTEXITCODE -ne 0) { throw "ACA CLI 설치 실패, exit=$LASTEXITCODE" }
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')
        Get-Command aca -ErrorAction Stop | Out-Null
        Write-Status -Level PASS -Message 'ACA CLI 명령을 확인했습니다.'
    }
    finally {
        Remove-Item -LiteralPath $installerDirectory -Recurse -Force -ErrorAction Stop
    }
}

function Install-WslUbuntu {
    Write-Status -Level INFO -Message 'WSL과 Ubuntu 상태를 확인합니다.'
    $features = @(Get-WslFeatures)
    if (Test-WslRestartPending $features) {
        Write-WslRestartRequired
        return 'RestartRequired'
    }
    Write-Status -Level INFO -Message 'Ubuntu 설치 전에 WSL 플랫폼을 확인합니다.'
    $install = Invoke-WslInstall -Arguments @('--install', '--no-distribution')
    if (Test-WslInstallRestartRequired $install) {
        Write-WslRestartRequired
        return 'RestartRequired'
    }
    if ($install.ExitCode -ne 0) { throw "WSL 플랫폼 설치 실패, exit=$($install.ExitCode).`n$($install.Output)" }
    $features = @(Get-WslFeatures)
    if (Test-WslRestartNeededAfterInstall $features) {
        Write-WslRestartRequired
        return 'RestartRequired'
    }
    $result = Get-UbuntuWslVersion
    if ($result.ExitCode -ne 0) {
        $notInstalled = @($features | Where-Object { $_.State.ToString() -ne 'Disabled' }).Count -eq 0
        if (-not $notInstalled -and -not (Test-NoWslDistribution $result.Output)) {
            throw "WSL 배포판 목록을 확인하지 못했습니다(exit=$($result.ExitCode)).`n$($result.Output)"
        }
    }
    $ubuntuVersion = $result.Version
    if ($null -eq $ubuntuVersion -and (Test-UbuntuPackageInstalled)) {
        Write-UbuntuFirstLaunchRequired
        return 'FirstLaunchRequired'
    }
    if ($null -eq $ubuntuVersion) {
        Write-Status -Level INFO -Message 'Ubuntu 설치를 시작합니다.'
        $install = Invoke-WslInstall -Arguments @('--install', '--distribution', 'Ubuntu', '--no-launch')
        if (Test-WslInstallRestartRequired $install) {
            Write-WslRestartRequired
            return 'RestartRequired'
        }
        if ($install.ExitCode -ne 0) { throw "Ubuntu 설치 실패, exit=$($install.ExitCode).`n$($install.Output)" }
        if (Test-WslRestartNeededAfterInstall @(Get-WslFeatures)) {
            Write-WslRestartRequired
            return 'RestartRequired'
        }
        $result = Get-UbuntuWslVersion
        if ($null -eq $result.Version -and (Test-NoWslDistribution $result.Output) -and (Test-UbuntuPackageInstalled)) {
            Write-UbuntuFirstLaunchRequired
            return 'FirstLaunchRequired'
        }
        if ($result.ExitCode -ne 0 -or $null -eq $result.Version) {
            throw "설치 후 Ubuntu의 WSL 버전을 확인하지 못했습니다(exit=$($result.ExitCode)). 설치 출력과 wsl.exe --status를 확인하세요.`n$($install.Output)`n$($result.Output)"
        }
        $ubuntuVersion = $result.Version
    }
    elseif ($ubuntuVersion -eq 2) {
        Write-Status -Level WARNING -Message 'WSL2 Ubuntu 배포판이 이미 있습니다. 변경하지 않습니다.'
    }
    if ($ubuntuVersion -eq 1) {
        Write-Status -Level WARNING -Message 'Ubuntu 배포판이 WSL1입니다. WSL2로 전환합니다.'
        & wsl.exe --set-version Ubuntu 2 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "Ubuntu를 WSL2로 전환하지 못했습니다(exit=$LASTEXITCODE)."
        }
        Write-Status -Level PASS -Message 'Ubuntu WSL2 전환 명령을 완료했습니다.'
        $result = Get-UbuntuWslVersion
        if ($result.ExitCode -ne 0) {
            throw "Ubuntu 전환 후 WSL 배포판 목록을 확인하지 못했습니다(exit=$($result.ExitCode)).`n$($result.Output)"
        }
        $ubuntuVersion = $result.Version
    }
    if ($ubuntuVersion -ne 2) {
        throw "Ubuntu가 WSL2인지 확인하지 못했습니다.`n$($result.Output)"
    }
    Write-Status -Level PASS -Message 'Ubuntu의 WSL2 구성을 확인했습니다.'
    & wsl.exe --set-default-version 2
    if ($LASTEXITCODE -ne 0) {
        Write-Status -Level WARNING -Message "WSL 기본 버전을 2로 지정하지 못했습니다(exit=$LASTEXITCODE). 재부팅 후 wsl --set-default-version 2를 실행하세요."
    }
    return 'Ready'
}

foreach ($group in $toolGroups) {
    Write-Status -Level INFO -Message "[$($group.Name)] 설치를 시작합니다."
    foreach ($step in $group.Steps) {
        switch ($step.Kind) {
            'winget' { Install-WingetPackage -Package $step }
            'node' { Install-Node }
            'aca' { Install-AcaCli }
            'wsl' {
                switch (Install-WslUbuntu) {
                    'RestartRequired' { exit 3010 }
                    'FirstLaunchRequired' { exit 2 }
                }
            }
            'hypervisor' {
                Write-Status -Level INFO -Message 'Windows Hypervisor Platform 활성화를 시작합니다.'
                Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart -ErrorAction Stop
                Write-Status -Level PASS -Message 'Windows Hypervisor Platform 활성화 명령을 완료했습니다. 재부팅이 필요할 수 있습니다.'
            }
            default { throw "알 수 없는 설치 단계: $($step.Kind)" }
        }
    }
    Write-Status -Level INFO -Message "[$($group.Name)] 설치 단계를 마쳤습니다."
}
Write-Status -Level PASS -Message '설치 명령 처리를 마쳤습니다. 재부팅 후 다시 로그인하고, Ubuntu와 Docker Desktop 첫 실행을 마친 뒤 버전과 모듈별 preflight를 확인하세요.'
Write-Status -Level INFO -Message 'Docker Desktop을 처음 실행해 약관을 확인하고 초기 설정을 마치세요.'
Write-Status -Level INFO -Message 'GitHub와 Azure 계정 인증은 각 도구에서 직접 진행하세요.'
