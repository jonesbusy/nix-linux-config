#!/usr/bin/env bash
set -Eeuo pipefail

export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
if [[ -n "${HERMES_PRIVATE_DRIFT_BIN_PATH:-}" ]]; then
  export PATH="${HERMES_PRIVATE_DRIFT_BIN_PATH}:${PATH:-}"
fi

python="${HERMES_PRIVATE_DRIFT_PYTHON:-python3}"
repo="$HOME/git/github/hermes-private-drift"
backup_script="$repo/scripts/backup_skills.py"
if [[ ! -f "$backup_script" ]]; then
  printf 'Hermes private drift backup: script missing at %s\n' "$backup_script" >&2
  exit 1
fi

exec "$python" "$backup_script" --hermes-home "$HERMES_HOME" --apply
