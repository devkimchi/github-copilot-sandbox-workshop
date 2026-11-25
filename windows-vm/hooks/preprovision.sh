#!/usr/bin/env bash
set -euo pipefail
command -v pwsh >/dev/null
hook_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
pwsh -NoLogo -NoProfile -File "$hook_dir/preprovision.ps1"
