#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$Patch,
    [string]$BackupRoot = (Join-Path $PSScriptRoot '..\evidence\backup')
)

$ErrorActionPreference = 'Stop'
$targetPath = (Resolve-Path -LiteralPath $Target).Path
$patchPath = (Resolve-Path -LiteralPath $Patch).Path
if (-not (Test-Path -LiteralPath (Join-Path $targetPath '.git') -PathType Container)) {
    throw '추출 스크립트로 만든 독립 Git 저장소만 복구합니다.'
}
if ((Split-Path $targetPath -Leaf) -notmatch '^workspace(?:-[A-Za-z0-9_-]+)?$') {
    throw '대상 이름은 workspace 또는 workspace-이름이어야 합니다.'
}
if (-not (Test-Path -LiteralPath $patchPath -PathType Leaf) -or (Get-Item -LiteralPath $patchPath).Length -eq 0) {
    throw '비어 있지 않은 검증된 패치 파일이 필요합니다.'
}
$prefix = $targetPath.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
$backupBase = [IO.Path]::GetFullPath($BackupRoot)
if ($patchPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
    $backupBase.Equals($targetPath, [StringComparison]::OrdinalIgnoreCase) -or
    $backupBase.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw '패치와 백업 폴더는 복구 대상 밖에 두어야 합니다.'
}
& git -C $targetPath rev-parse --verify 'refs/tags/baseline^{commit}'
if ($LASTEXITCODE -ne 0) { throw 'baseline 태그가 없습니다.' }
Get-Command tar.exe -ErrorAction Stop | Out-Null
$untracked = @(& git -C $targetPath -c core.quotepath=false ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0) { throw 'untracked 파일 목록 확인 실패' }
foreach ($file in $untracked) {
    if ($file.StartsWith('"')) { throw '특수 문자가 있는 파일명은 수동 백업/복구가 필요합니다.' }
    $source = [IO.Path]::GetFullPath((Join-Path $targetPath $file))
    if (-not $source.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "대상 밖 파일은 이동하지 않습니다: $file"
    }
}

$backup = Join-Path $backupBase "$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $backup -ErrorAction Stop | Out-Null
& tar.exe -czf (Join-Path $backup 'snapshot.tar.gz') -C $targetPath .
if ($LASTEXITCODE -ne 0) { throw "전체 백업 실패. 복구하지 않습니다: $backup" }
& git -C $targetPath diff --binary "--output=$(Join-Path $backup 'from-baseline.patch')" baseline --
if ($LASTEXITCODE -ne 0) { throw 'diff 백업 실패. 복구하지 않습니다.' }
& git -C $targetPath status --short | Out-File (Join-Path $backup 'status.txt')
if ($LASTEXITCODE -ne 0) { throw '상태 기록 실패. 복구하지 않습니다.' }

Write-Host "백업(ignored 파일, .git 포함): $backup"
Write-Host "파일과 index를 baseline으로 복구합니다. HEAD/브랜치는 이동하지 않습니다: $targetPath"
$answer = Read-Host '계속하려면 RESTORE를 입력하세요'
if ($answer -cne 'RESTORE') { throw '사용자가 복구를 취소했습니다. 백업은 보존합니다.' }

foreach ($file in $untracked) {
    $source = Join-Path $targetPath $file
    $destination = Join-Path (Join-Path $backup 'untracked') $file
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Move-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
}
& git -C $targetPath restore --source=baseline --staged --worktree -- .
if ($LASTEXITCODE -ne 0) { throw "baseline 파일 복구 실패. 백업 확인: $backup" }
& git -C $targetPath apply --check -- $patchPath
if ($LASTEXITCODE -ne 0) { throw "패치 사전 검사 실패. baseline 파일 상태에서 중단. 백업: $backup" }
& git -C $targetPath apply -- $patchPath
if ($LASTEXITCODE -ne 0) { throw "패치 적용 실패. 백업 확인: $backup" }
Write-Output "패치 적용 완료. 사람이 diff와 테스트를 확인하세요. 백업: $backup"
