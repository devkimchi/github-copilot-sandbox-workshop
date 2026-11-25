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
        $lines = @(& wsl.exe --list --verbose 2>$null)
        if ($LASTEXITCODE -ne 0) {
            Write-Status -Level WARNING -Message "WSL 배포판 목록을 확인하지 못했습니다(exit=$LASTEXITCODE)."
            return $null
        }
        foreach ($line in $lines) {
            $fields = @(($line -replace '^\s*\*', '').Trim() -split '\s+')
            if ($fields.Count -ge 3 -and $fields[0] -eq 'Ubuntu') { return [int]$fields[-1] }
        }
        return $null
    }
    catch {
        Write-Status -Level WARNING -Message "WSL 배포판 목록을 확인하지 못했습니다($($_.Exception.Message))."
        return $null
    }
    finally {
        $env:WSL_UTF8 = $previousWslUtf8
    }
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
    Get-Command npm.cmd -ErrorAction Stop | Out-Null
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
    $ubuntuVersion = Get-UbuntuWslVersion
    if ($null -eq $ubuntuVersion) {
        Write-Status -Level INFO -Message 'WSL과 Ubuntu 설치를 시작합니다.'
        & wsl.exe --install --distribution Ubuntu --no-launch
        if ($LASTEXITCODE -ne 0) { throw "WSL2와 Ubuntu 설치 실패, exit=$LASTEXITCODE" }
        Write-Status -Level PASS -Message 'WSL과 Ubuntu 설치 명령을 완료했습니다. 재부팅이 필요할 수 있습니다.'
        $ubuntuVersion = Get-UbuntuWslVersion
        if ($null -eq $ubuntuVersion) {
            throw 'Ubuntu의 WSL 버전을 확인하지 못했습니다. 재부팅하고 Ubuntu 첫 실행을 마친 뒤 스크립트를 다시 실행하세요.'
        }
    }
    elseif ($ubuntuVersion -eq 2) {
        Write-Status -Level WARNING -Message 'WSL2 Ubuntu 배포판이 이미 있습니다. 변경하지 않습니다.'
    }
    if ($ubuntuVersion -eq 1) {
        Write-Status -Level WARNING -Message 'Ubuntu 배포판이 WSL1입니다. WSL2로 전환합니다.'
        & wsl.exe --install --no-distribution
        if ($LASTEXITCODE -ne 0) { throw "WSL2 구성 요소 설치 실패, exit=$LASTEXITCODE" }
        & wsl.exe --set-version Ubuntu 2
        if ($LASTEXITCODE -ne 0) {
            throw "Ubuntu를 WSL2로 전환하지 못했습니다(exit=$LASTEXITCODE). 재부팅한 뒤 스크립트를 다시 실행하세요."
        }
        Write-Status -Level PASS -Message 'Ubuntu WSL2 전환 명령을 완료했습니다.'
        $ubuntuVersion = Get-UbuntuWslVersion
    }
    if ($ubuntuVersion -ne 2) {
        throw 'Ubuntu가 WSL2인지 확인하지 못했습니다. 재부팅하고 상태를 확인한 뒤 스크립트를 다시 실행하세요.'
    }
    Write-Status -Level PASS -Message 'Ubuntu의 WSL2 구성을 확인했습니다.'
    & wsl.exe --set-default-version 2
    if ($LASTEXITCODE -ne 0) {
        Write-Status -Level WARNING -Message "WSL 기본 버전을 2로 지정하지 못했습니다(exit=$LASTEXITCODE). 재부팅 후 wsl --set-default-version 2를 실행하세요."
    }
}

foreach ($group in $toolGroups) {
    Write-Status -Level INFO -Message "[$($group.Name)] 설치를 시작합니다."
    foreach ($step in $group.Steps) {
        switch ($step.Kind) {
            'winget' { Install-WingetPackage -Package $step }
            'node' { Install-Node }
            'aca' { Install-AcaCli }
            'wsl' { Install-WslUbuntu }
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
Write-Status -Level INFO -Message 'Docker Desktop 첫 실행에서는 약관에 동의해야 합니다. 로그인, PAT 입력, 샌드박스 생성과 모델 호출은 하지 않았습니다. 중첩 가상화 지원도 보장하지 않습니다.'
