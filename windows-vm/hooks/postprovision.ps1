#requires -Version 7.0
$ErrorActionPreference = 'Stop'
foreach ($name in 'AZURE_VM_NAME', 'AZURE_RESOURCE_GROUP', 'AZURE_VM_ADMIN_USERNAME') {
    $value = & azd env get-value $name --environment $env:AZURE_ENV_NAME
    if ($LASTEXITCODE -ne 0) { throw "배포 출력 확인 실패: $name" }
    Write-Host "$name=$value"
}
Write-Host 'Azure portal의 해당 VM > 연결 > Bastion으로 접속하세요.'
Write-Host 'C:\WorkshopSetup\install-tools.ps1은 전달만 했습니다. 사용자 세션에서 내용을 검토하고 별도 실행하세요.'
Write-Host 'VM 부팅/도구 설치만으로 Copilot 샌드박스와 Docker 중첩 가상화 지원이 검증되지는 않습니다.'
