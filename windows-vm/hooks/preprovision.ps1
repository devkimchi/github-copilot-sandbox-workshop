#requires -Version 7.0
$ErrorActionPreference = 'Stop'
foreach ($name in 'AZURE_ENV_NAME', 'AZURE_LOCATION', 'AZURE_SUBSCRIPTION_ID') {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value) -or $value -match 'TBD|<|>') {
        throw "azd 환경 변수 $name 값을 실제 검증 값으로 설정하세요."
    }
}
$imageVersion = [Environment]::GetEnvironmentVariable('WORKSHOP_VM_IMAGE_VERSION')
if ($null -ne $imageVersion -and $imageVersion -cne 'latest' -and $imageVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw 'WORKSHOP_VM_IMAGE_VERSION은 latest 또는 확인한 고정 숫자 버전이어야 합니다.'
}
