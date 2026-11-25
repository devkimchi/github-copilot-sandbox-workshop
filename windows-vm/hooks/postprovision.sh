#!/usr/bin/env bash
set -euo pipefail

for name in AZURE_VM_NAME AZURE_RESOURCE_GROUP AZURE_VM_ADMIN_USERNAME; do
  if ! value="$(azd env get-value "$name" --environment "${AZURE_ENV_NAME:-}")"; then
    echo "배포 출력 확인 실패: $name" >&2
    exit 1
  fi
  echo "$name=$value"
done

echo 'Azure portal의 해당 VM > 연결 > Bastion으로 접속하세요.'
echo 'C:\WorkshopSetup\install-tools.ps1은 전달만 했습니다. 사용자 세션에서 내용을 검토하고 별도 실행하세요.'
echo 'VM 부팅/도구 설치만으로 Copilot 샌드박스와 Docker 중첩 가상화 지원이 검증되지는 않습니다.'
