#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  printf '%s\n' '사용법: bash restore-checkpoint.sh <workspace> <patch> [대상 밖 backup 폴더]' >&2
  exit 2
fi
for tool in git tar realpath mktemp; do command -v "$tool" >/dev/null; done
target="$(realpath "$1")"
patch="$(realpath "$2")"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
backup_root="$(realpath -m "${3:-$script_dir/../evidence/backup}")"
if [[ ! "$(basename "$target")" =~ ^workspace(-[A-Za-z0-9_-]+)?$ || ! -d "$target/.git" || ! -s "$patch" ]]; then
  printf '%s\n' '독립 workspace Git 저장소와 비어 있지 않은 검증된 패치가 필요합니다.' >&2
  exit 1
fi
if [[ "$patch" == "$target/"* || "$backup_root" == "$target" || "$backup_root" == "$target/"* ]]; then
  printf '%s\n' '패치와 백업은 복구 대상 밖에 두어야 합니다.' >&2
  exit 1
fi
git -C "$target" rev-parse --verify 'refs/tags/baseline^{commit}'
mkdir -p "$backup_root"
backup="$(mktemp -d "$backup_root/restore.XXXXXXXX")"
tar -czf "$backup/snapshot.tar.gz" -C "$target" .
git -C "$target" diff --binary --output="$backup/from-baseline.patch" baseline --
git -C "$target" status --short > "$backup/status.txt"
git -C "$target" ls-files --others --exclude-standard -z > "$backup/untracked.list"
printf '전체 백업(ignored 파일, .git 포함): %s\n대상: %s\n' "$backup" "$target"
printf '%s\n' 'HEAD/브랜치는 보존하고 파일과 index를 baseline으로 복구합니다.'
read -r -p '계속하려면 RESTORE를 입력하세요: ' answer
if [[ "$answer" != RESTORE ]]; then
  printf '%s\n' '복구 취소. 백업은 보존합니다.' >&2
  exit 1
fi
while IFS= read -r -d '' file; do
  if [[ "$file" == /* || "$file" == ../* || "$file" == */../* ]]; then
    printf '대상 밖 파일 이동 거부: %s\n' "$file" >&2
    exit 1
  fi
  mkdir -p "$backup/untracked/$(dirname -- "$file")"
  mv -- "$target/$file" "$backup/untracked/$file"
done < "$backup/untracked.list"
git -C "$target" restore --source=baseline --staged --worktree -- .
if ! git -C "$target" apply --check -- "$patch"; then
  printf '패치 사전 검사 실패. baseline 파일 상태에서 중단. 백업: %s\n' "$backup" >&2
  exit 1
fi
git -C "$target" apply -- "$patch"
printf '패치 적용 완료. 사람이 diff와 테스트를 확인하세요. 백업: %s\n' "$backup"
