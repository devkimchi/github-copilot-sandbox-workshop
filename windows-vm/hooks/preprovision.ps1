#requires -Version 7.0
$ErrorActionPreference = 'Stop'
foreach ($name in 'AZURE_ENV_NAME', 'AZURE_LOCATION', 'AZURE_SUBSCRIPTION_ID', 'WORKSHOP_CONFIRM_WINDOWS_LICENSE') {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value) -or $value -match 'TBD|<|>') {
        throw "azd 환경 변수 $name 값을 실제 검증 값으로 설정하세요."
    }
}
if ($env:WORKSHOP_CONFIRM_WINDOWS_LICENSE -cne 'true') {
    throw 'Windows 클라이언트 라이선스 자격을 확인한 뒤 WORKSHOP_CONFIRM_WINDOWS_LICENSE=true를 설정하세요.'
}
$imageVersion = [Environment]::GetEnvironmentVariable('WORKSHOP_VM_IMAGE_VERSION')
if ($null -ne $imageVersion -and $imageVersion -cne 'latest' -and $imageVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw 'WORKSHOP_VM_IMAGE_VERSION은 latest 또는 확인한 고정 숫자 버전이어야 합니다.'
}
Write-Host '구문상 필수 입력만 확인했습니다. 지역/SKU/이미지/Bastion/할당량과 비용은 확인하지 않았습니다.'
Write-Host 'Trusted Launch, Secure Boot와 vTPM을 유지합니다. Docker 중첩 가상화는 미검증입니다.'
$answer = Read-Host '본인 구독, 비용, 라이선스와 지역별 가용성을 확인했으면 PROVISION을 입력하세요'
if ($answer -cne 'PROVISION') { throw '사용자가 VM provision을 취소했습니다.' }
