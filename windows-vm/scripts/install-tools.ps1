#requires -Version 5.1
#requires -RunAsAdministrator
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^\d+(\.\d+){1,3}$')][string]$GitVersion,
    [Parameter(Mandatory)][ValidatePattern('^2\.\d+\.\d+$')][string]$NvmVersion,
    [Parameter(Mandatory)][ValidatePattern('^24\.\d+\.\d+$')][string]$NodeVersion,
    [Parameter(Mandatory)][ValidatePattern('^\d+(\.\d+){1,3}$')][string]$PowerShellVersion,
    [Parameter(Mandatory)][ValidatePattern('^\d+(\.\d+){1,3}$')][string]$AzureCliVersion,
    [Parameter(Mandatory)][ValidatePattern('^\d+(\.\d+){1,3}$')][string]$SbxVersion,
    [Parameter(Mandatory)][ValidatePattern('^\d+(\.\d+){1,3}$')][string]$CopilotVersion,
    [Parameter(Mandatory)][string]$AcaExecutablePath,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{64}$')][string]$AcaSha256,
    [switch]$EnableHypervisorPlatform
)

$ErrorActionPreference = 'Stop'
if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    throw 'SYSTEM이 아닌 실제 로그인한 관리자 사용자로 실행하세요.'
}
Get-Command winget.exe -ErrorAction Stop | Out-Null
$acaSource = (Resolve-Path -LiteralPath $AcaExecutablePath).Path
if ([IO.Path]::GetExtension($acaSource) -ne '.exe' -or
    (Get-FileHash -LiteralPath $acaSource -Algorithm SHA256).Hash -ne $AcaSha256) {
    throw 'ACA 실행 파일 형식 또는 SHA-256이 확인한 값과 다릅니다.'
}
$packages = @(
    @{ Id = 'Git.Git'; Version = $GitVersion; Command = 'git.exe' },
    @{ Id = 'AuthorSoftware.NVMWindows'; Version = $NvmVersion; Command = 'nvm.exe' },
    @{ Id = 'Microsoft.PowerShell'; Version = $PowerShellVersion; Command = 'pwsh.exe' },
    @{ Id = 'Microsoft.AzureCLI'; Version = $AzureCliVersion; Command = 'az.cmd' },
    @{ Id = 'Docker.sbx'; Version = $SbxVersion; Command = 'sbx.exe' }
)
$existingNode = Get-Command node.exe -ErrorAction SilentlyContinue
if ($existingNode -and -not (Get-Command nvm.exe -ErrorAction SilentlyContinue)) {
    throw "nvm-windows 밖에서 설치한 Node.js가 있습니다($($existingNode.Source)). 원래 설치 프로그램으로 제거한 뒤 다시 실행하세요."
}
$packages | ForEach-Object { Write-Host "$($_.Id) @ $($_.Version)" }
Write-Host "Node.js @ $NodeVersion (nvm-windows로 설치)"
Write-Host "Copilot npm @ $CopilotVersion, ACA 실행 파일 SHA-256 검증 완료"
if ($EnableHypervisorPlatform) {
    Write-Host 'Windows Hypervisor Platform 활성화를 요청했습니다. 재부팅이 필요할 수 있습니다.'
}
$answer = Read-Host '설치와 표시한 패키지 사용 조건을 검토한 뒤 INSTALL을 입력하세요'
if ($answer -cne 'INSTALL') { throw '사용자가 도구 설치를 취소했습니다.' }
foreach ($package in $packages) {
    if (Get-Command $package.Command -ErrorAction SilentlyContinue) {
        Write-Warning "$($package.Command)이 이미 있습니다. 변경하지 않습니다. 요청 버전과 실제 버전을 직접 비교하세요."
        continue
    }
    & winget.exe install --id $package.Id --exact --version $package.Version --source winget --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "패키지 설치 실패: $($package.Id), exit=$LASTEXITCODE" }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
}
$actualNvm = & nvm.exe version
if ($LASTEXITCODE -ne 0 -or $actualNvm -notmatch '^v?2\.') {
    throw "nvm-windows 2.x가 필요합니다. 현재 버전: $actualNvm"
}
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
if (Get-Command copilot -ErrorAction SilentlyContinue) {
    Write-Warning '기존 Copilot CLI를 보존합니다. 실제 버전을 요청 값과 직접 비교하세요.'
}
else {
    & npm.cmd install --global "@github/copilot@$CopilotVersion"
    if ($LASTEXITCODE -ne 0) { throw 'Copilot CLI 설치 실패' }
}
$bin = Join-Path $env:LOCALAPPDATA 'WorkshopTools'
New-Item -ItemType Directory -Path $bin -Force | Out-Null
$acaDestination = Join-Path $bin 'aca.exe'
if (Test-Path -LiteralPath $acaDestination) {
    if ((Get-FileHash -LiteralPath $acaDestination -Algorithm SHA256).Hash -ne $AcaSha256) {
        throw '기존 ACA 실행 파일이 다른 내용입니다. 자동 덮어쓰지 않습니다.'
    }
}
else {
    Copy-Item -LiteralPath $acaSource -Destination $acaDestination -ErrorAction Stop
}
$userPath = [string][Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $bin) {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $bin), 'User')
}
if ($EnableHypervisorPlatform) {
    Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart -ErrorAction Stop
}
Write-Output '도우미 실행 완료. 다시 로그인하고 필요한 재부팅 후 버전과 모듈별 preflight를 확인하세요.'
Write-Output '로그인, PAT 입력, 샌드박스 생성과 모델 호출은 하지 않았습니다. 중첩 가상화 지원도 보장하지 않습니다.'
