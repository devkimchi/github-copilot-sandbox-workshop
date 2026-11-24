#requires -Version 7.0
[CmdletBinding()]
param(
    [ValidatePattern('^workspace(?:-[A-Za-z0-9_-]+)?$')]
    [string]$Target = 'workspace'
)

$ErrorActionPreference = 'Stop'
$sha = '9cd9a450f923c7a084bd47d661877d82ff710826'
$paths = @(
    '.gitignore', 'LICENSE', 'astro.config.mjs', 'db', 'drizzle.config.ts',
    'e2e-tests', 'eslint.config.js', 'package.json', 'package-lock.json',
    'playwright.config.ts', 'public', 'src', 'tsconfig.json',
    'tsconfig.tsgo.json', 'vitest.config.ts'
)
$destination = Join-Path (Get-Location).Path $Target
if (Test-Path -LiteralPath $destination) {
    throw "대상이 이미 존재합니다. 덮어쓰지 않습니다: $destination"
}
foreach ($tool in 'git', 'curl.exe', 'tar.exe') {
    Get-Command $tool -ErrorAction Stop | Out-Null
}

$temp = Join-Path ([IO.Path]::GetTempPath()) "tailspin-workshop-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $archive = Join-Path $temp 'tailspin.tar.gz'
    $staging = Join-Path $temp 'app'
    New-Item -ItemType Directory -Path $staging | Out-Null
    & curl.exe -fsSL --output $archive "https://github.com/github-samples/tailspin-toys/archive/$sha.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw '고정 스냅샷 다운로드 실패' }
    $members = $paths | ForEach-Object { "tailspin-toys-$sha/$_" }
    & tar.exe -xzf $archive -C $staging --strip-components=1 @members
    if ($LASTEXITCODE -ne 0) { throw '앱 파일 추출 실패' }
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath (Join-Path $staging $path))) {
            throw "필수 추출 경로 누락: $path"
        }
    }
    Move-Item -LiteralPath $staging -Destination $destination -ErrorAction Stop
    & git -C $destination init --initial-branch=main --quiet
    if ($LASTEXITCODE -ne 0) { throw "Git 초기화 실패. 부분 결과 확인: $destination" }
    & git -C $destination config core.autocrlf false
    if ($LASTEXITCODE -ne 0) { throw 'Git 줄 끝 설정 실패' }
    & git -C $destination add -A
    if ($LASTEXITCODE -ne 0) { throw '기준 파일 staging 실패' }
    & git -C $destination -c user.name=workshop -c user.email=workshop@example.invalid -c commit.gpgsign=false commit --quiet -m "Tailspin Toys app files @ $sha" -m 'Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
    if ($LASTEXITCODE -ne 0) { throw '기준 커밋 생성 실패' }
    & git -C $destination tag baseline
    if ($LASTEXITCODE -ne 0) { throw 'baseline 태그 생성 실패' }
    Write-Output "앱 준비 완료: $destination (원본 $sha). 의존성 설치와 테스트는 실행하지 않았습니다."
}
finally {
    # 이 실행에서 만든 전용 임시 폴더만 정리한다. 대상 workspace는 실패해도 보존한다.
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction Stop
}
