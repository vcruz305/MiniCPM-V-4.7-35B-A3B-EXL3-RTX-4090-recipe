#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/env.sh"
# WSL2 and many desktop setups default to 1024 open files; the CUDA driver then fails
# mid-load with "CUDA driver error: unknown error"
ulimit -n 65536 2>/dev/null || ulimit -n "$(ulimit -Hn)" 2>/dev/null || true
if [[ "${DRY_RUN:-0}" == 1 ]]; then
  exec python3 "$RECIPE_ROOT/tools/manage.py" preview "$@"
fi
exec python3 "$RECIPE_ROOT/tools/manage.py" serve "$@"
