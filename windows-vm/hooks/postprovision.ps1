#requires -Version 7.0
$ErrorActionPreference = 'Stop'
foreach ($name in 'AZURE_VM_NAME', 'AZURE_RESOURCE_GROUP', 'AZURE_VM_ADMIN_USERNAME') {
    $value = & azd env get-value $name --environment $env:AZURE_ENV_NAME
    if ($LASTEXITCODE -ne 0) { throw "배포 출력 확인 실패: $name" }
    Write-Host "$name=$value"
}
Write-Host 'Azure portal의 해당 VM > 연결 > Bastion으로 접속하세요.'
