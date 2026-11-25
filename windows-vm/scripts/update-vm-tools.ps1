#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('\A[0-9a-fA-F]{40}\z')]
    [string]$CommitSha
)

$ErrorActionPreference = 'Stop'
$target = Join-Path $PSScriptRoot 'install-vm-tools.ps1'
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    throw "설치 스크립트가 없습니다: $target"
}

$suffix = '{0}.{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), ([guid]::NewGuid().ToString('N'))
$backup = "$target.$suffix.bak"
$temporary = Join-Path $PSScriptRoot ".install-vm-tools.$suffix.tmp"
$url = "https://raw.githubusercontent.com/devkimchi/github-copilot-sandbox-workshop/$CommitSha/windows-vm/scripts/install-vm-tools.ps1"
$previousProtocol = [Net.ServicePointManager]::SecurityProtocol

try {
    Copy-Item -LiteralPath $target -Destination $backup -ErrorAction Stop
    Write-Host "[INFO] 기존 파일을 백업했습니다: $backup"

    [Net.ServicePointManager]::SecurityProtocol = $previousProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $temporary -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
    $content = [IO.File]::ReadAllText($temporary, [Text.Encoding]::UTF8)

    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseInput(
        $content, [ref]$tokens, [ref]$parseErrors
    ) | Out-Null
    if ([string]::IsNullOrWhiteSpace($content) -or $parseErrors.Count -gt 0) {
        throw "다운로드한 스크립트가 비어 있거나 구문 오류가 있습니다.`n$($parseErrors | Out-String)"
    }

    [IO.File]::WriteAllText($temporary, $content, (New-Object Text.UTF8Encoding $true))
    # An untyped $null becomes an empty backup path when PowerShell calls this method.
    [IO.File]::Replace($temporary, $target, [NullString]::Value)
    Write-Host "[PASS] 설치 스크립트를 갱신했습니다: $target (commit=$CommitSha)"
    Write-Host '[INFO] 설치 스크립트를 검토한 뒤 별도로 실행하세요. 자동 실행하지 않았습니다.'
}
finally {
    [Net.ServicePointManager]::SecurityProtocol = $previousProtocol
    if (Test-Path -LiteralPath $temporary) {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction Stop
    }
}
