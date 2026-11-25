#requires -Version 5.1
#requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$EnableHypervisorPlatform,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    throw 'SYSTEM이 아닌 실제 로그인한 관리자 사용자로 실행하세요.'
}
Get-Command winget.exe -ErrorAction Stop | Out-Null
$packages = @(
    @{ Id = 'Git.Git'; Command = 'git.exe' },
    @{ Id = 'GitHub.cli'; Command = 'gh.exe' },
    @{ Id = 'AuthorSoftware.NVMWindows'; Command = 'nvm.exe' },
    @{ Id = 'Microsoft.PowerShell'; Command = 'pwsh.exe' },
    @{ Id = 'Microsoft.AzureCLI'; Command = 'az.cmd' },
    @{ Id = 'Docker.sbx'; Command = 'sbx.exe' },
    @{ Id = 'Docker.DockerDesktop'; Command = 'docker.exe' },
    @{ Id = 'GitHub.Copilot'; Command = 'copilot.exe' }
)
$existingNode = Get-Command node.exe -ErrorAction SilentlyContinue
if ($existingNode -and -not (Get-Command nvm.exe -ErrorAction SilentlyContinue)) {
    throw "nvm-windows 밖에서 설치한 Node.js가 있습니다($($existingNode.Source)). 원래 설치 프로그램으로 제거한 뒤 다시 실행하세요."
}
$packages | ForEach-Object { Write-Host "$($_.Id): WinGet에서 제공하는 최신 버전" }
Write-Host 'WSL2와 Ubuntu: wsl --install로 설치. 재부팅과 Ubuntu 첫 실행 시 사용자 생성이 필요할 수 있음'
Write-Host 'Node.js: nvm-windows 2.x를 통해 24.x 최신 버전 설치'
Write-Host 'ACA CLI: 공식 설치 스크립트 https://aka.ms/aca-cli-install-ps 사용'
if ($EnableHypervisorPlatform) {
    Write-Host 'Windows Hypervisor Platform 활성화를 요청했습니다. 재부팅이 필요할 수 있습니다.'
}
if ($Yes) {
    Write-Host '-Yes 옵션으로 설치와 패키지 사용 조건에 동의한 것으로 간주합니다.'
}
else {
    $answer = Read-Host '설치와 표시한 패키지 사용 조건을 검토한 뒤 INSTALL을 입력하세요'
    if ($answer -cne 'INSTALL') { throw '사용자가 도구 설치를 취소했습니다.' }
}
$previousWslUtf8 = $env:WSL_UTF8
$env:WSL_UTF8 = '1'
try {
    $distributions = @(& wsl.exe --list --quiet 2>$null | ForEach-Object { $_.Trim() })
    $hasUbuntu = $LASTEXITCODE -eq 0 -and ($distributions -contains 'Ubuntu')
}
catch {
    $hasUbuntu = $false
}
finally {
    $env:WSL_UTF8 = $previousWslUtf8
}
if ($hasUbuntu) {
    Write-Warning 'WSL Ubuntu 배포판이 이미 있습니다. 변경하지 않습니다.'
}
else {
    & wsl.exe --install --distribution Ubuntu --no-launch
    if ($LASTEXITCODE -ne 0) { throw "WSL2와 Ubuntu 설치 실패, exit=$LASTEXITCODE" }
}
foreach ($package in $packages) {
    if (Get-Command $package.Command -ErrorAction SilentlyContinue) {
        Write-Warning "$($package.Command)이 이미 있습니다. 변경하지 않습니다. 최신 버전이 필요한 경우 원래 설치 경로로 직접 업데이트하세요."
        continue
    }
    & winget.exe install --id $package.Id --exact --source winget --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "패키지 설치 실패: $($package.Id), exit=$LASTEXITCODE" }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
}
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
if (Get-Command aca -ErrorAction SilentlyContinue) {
    Write-Warning '기존 ACA CLI를 보존합니다. 최신 버전이 필요한 경우 원래 설치 경로로 직접 업데이트하세요.'
}
else {
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
    }
    finally {
        Remove-Item -LiteralPath $installerDirectory -Recurse -Force -ErrorAction Stop
    }
}
if ($EnableHypervisorPlatform) {
    Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart -ErrorAction Stop
}
Write-Output '도우미 실행 완료. 재부팅 후 다시 로그인하고, Ubuntu 첫 실행과 Docker Desktop 첫 실행(약관 동의)을 마친 뒤 버전과 모듈별 preflight를 확인하세요.'
Write-Output '로그인, PAT 입력, 샌드박스 생성과 모델 호출은 하지 않았습니다. 중첩 가상화 지원도 보장하지 않습니다.'
