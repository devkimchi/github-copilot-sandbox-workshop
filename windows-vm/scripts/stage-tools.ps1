$ErrorActionPreference = 'Stop'
$directory = 'C:\WorkshopSetup'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$destination = Join-Path $directory 'install-tools.ps1'
$content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__INSTALLER_BASE64__'))
# Windows PowerShell 5.1에서도 한국어 안내를 읽도록 BOM을 포함한다.
[IO.File]::WriteAllText($destination, $content, (New-Object Text.UTF8Encoding $true))
Write-Output "사용자 설치 도우미 전달 완료: $destination. 도구 설치는 실행하지 않았습니다."
