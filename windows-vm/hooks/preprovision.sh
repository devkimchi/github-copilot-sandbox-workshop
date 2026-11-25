#!/usr/bin/env bash
set -euo pipefail

for name in AZURE_ENV_NAME AZURE_LOCATION AZURE_SUBSCRIPTION_ID; do
  value="${!name:-}"
  if [[ -z "${value//[[:space:]]/}" || "$value" == *TBD* || "$value" == *[\<\>]* ]]; then
    echo "azd 환경 변수 $name 값을 실제 검증 값으로 설정하세요." >&2
    exit 1
  fi
done

if [[ -n "${WORKSHOP_VM_IMAGE_VERSION+x}" ]]; then
  image_version="$WORKSHOP_VM_IMAGE_VERSION"
  if [[ "$image_version" != "latest" && ! "$image_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "WORKSHOP_VM_IMAGE_VERSION은 latest 또는 확인한 고정 숫자 버전이어야 합니다." >&2
    exit 1
  fi
fi
