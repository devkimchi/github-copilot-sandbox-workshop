# Keep this Run Command entry script ASCII for Windows PowerShell 5.1.
$ErrorActionPreference = 'Stop'
$directory = 'C:\WorkshopSetup'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$destination = Join-Path $directory 'install-tools.ps1'
$content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__INSTALLER_BASE64__'))
[IO.File]::WriteAllText($destination, $content, (New-Object Text.UTF8Encoding $true))
Write-Output "Installer staged at $destination. No tools were installed."
