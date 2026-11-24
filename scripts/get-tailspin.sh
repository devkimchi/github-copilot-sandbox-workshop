#!/usr/bin/env bash
set -euo pipefail

target="${1:-workspace}"
if [[ $# -gt 1 || ! "$target" =~ ^workspace(-[A-Za-z0-9_-]+)?$ ]]; then
  printf '%s\n' '사용법: bash get-tailspin.sh [workspace 또는 workspace-이름]' >&2
  exit 2
fi
if [[ -e "$target" || -L "$target" ]]; then
  printf '대상이 이미 존재합니다. 덮어쓰지 않습니다: %s\n' "$target" >&2
  exit 1
fi
for tool in git curl tar mktemp; do command -v "$tool" >/dev/null; done

sha=9cd9a450f923c7a084bd47d661877d82ff710826
paths=(
  .gitignore LICENSE astro.config.mjs db drizzle.config.ts e2e-tests
  eslint.config.js package.json package-lock.json playwright.config.ts
  public src tsconfig.json tsconfig.tsgo.json vitest.config.ts
)
temp="$(mktemp -d "${TMPDIR:-/tmp}/tailspin-workshop.XXXXXXXX")"
trap 'rm -rf -- "$temp"' EXIT
trap 'printf "%s\n" "추출 실패. 부분 workspace가 있다면 보존했습니다." >&2' ERR
mkdir "$temp/app"
curl -fsSL --output "$temp/tailspin.tar.gz" \
  "https://github.com/github-samples/tailspin-toys/archive/$sha.tar.gz"
members=()
for path in "${paths[@]}"; do members+=("tailspin-toys-$sha/$path"); done
tar -xzf "$temp/tailspin.tar.gz" -C "$temp/app" --strip-components=1 "${members[@]}"
for path in "${paths[@]}"; do
  if [[ ! -e "$temp/app/$path" ]]; then
    printf '필수 추출 경로 누락: %s\n' "$path" >&2
    exit 1
  fi
done
mv "$temp/app" "$target"
git -C "$target" init --initial-branch=main --quiet
git -C "$target" config core.autocrlf false
git -C "$target" add -A
git -C "$target" -c user.name=workshop -c user.email=workshop@example.invalid \
  -c commit.gpgsign=false commit --quiet -m "Tailspin Toys app files @ $sha" \
  -m 'Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
git -C "$target" tag baseline
printf '앱 준비 완료: %s (원본 %s). 의존성 설치와 테스트는 실행하지 않았습니다.\n' "$target" "$sha"
