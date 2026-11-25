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
