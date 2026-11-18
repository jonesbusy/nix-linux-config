#!/usr/bin/env bash
set -Eeuo pipefail

# Skip system SSH config files that appear untrusted inside the Hermes user namespace.
export GIT_SSH_COMMAND='ssh -F /dev/null -o BatchMode=yes'

repo="/home/valentin/.pi/agent/memory"
lock="/home/valentin/.pi/agent/.memory-backup.lock"

exec 9>"$lock"
flock -n 9 || exit 0

cd "$repo"
git rev-parse --is-inside-work-tree >/dev/null
branch="$(git branch --show-current)"
if [[ -z "$branch" ]]; then
  printf 'Pi memory backup: detached HEAD; refusing to push.\n' >&2
  exit 1
fi

# Reconcile remote updates before recording this run's snapshot.
git pull --quiet --rebase --autostash origin "$branch"
git add -A -- .
committed=0
if ! git diff --cached --quiet; then
  git commit --quiet -m "Save Pi agent memory ($(date -Is))"
  committed=1
fi
# Always push, including a previous commit whose push may have failed.
git push --quiet origin "$branch"
if (( committed )); then
  printf 'Pi memory backup: committed and pushed on %s.\n' "$branch"
fi
