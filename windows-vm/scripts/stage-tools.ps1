# Keep this Run Command entry script ASCII for Windows PowerShell 5.1.
$ErrorActionPreference = 'Stop'
$userName = '__ADMIN_USERNAME__'
$sid = (New-Object Security.Principal.NTAccount($userName)).Translate([Security.Principal.SecurityIdentifier]).Value
$profileKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
if (Test-Path -LiteralPath $profileKey) {
    $profilePath = (Get-ItemProperty -LiteralPath $profileKey).ProfileImagePath
}
else {
    # Before the first sign-in, new profiles are copied from the Default profile.
    $profilePath = Join-Path $env:SystemDrive 'Users\Default'
}
$directory = Join-Path $profilePath 'scripts'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$destination = Join-Path $directory 'install-vm-tools.ps1'
$content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__INSTALLER_BASE64__'))
[IO.File]::WriteAllText($destination, $content, (New-Object Text.UTF8Encoding $true))
Write-Output "Installer staged at $destination. No tools were installed."