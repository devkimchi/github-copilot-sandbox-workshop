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
$scripts = [ordered]@{
    'install-vm-tools.ps1' = '__INSTALLER_BASE64__'
    'update-vm-tools.ps1' = '__UPDATER_BASE64__'
}
foreach ($script in $scripts.GetEnumerator()) {
    $destination = Join-Path $directory $script.Key
    $content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($script.Value))
    [IO.File]::WriteAllText($destination, $content, (New-Object Text.UTF8Encoding $true))
    Write-Output "Script staged at $destination. No tools were installed."
}