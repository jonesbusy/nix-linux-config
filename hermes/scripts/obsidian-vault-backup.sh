#!/usr/bin/env bash
set -Eeuo pipefail

# Skip system SSH config files that appear untrusted inside the Hermes user namespace.
export GIT_SSH_COMMAND='ssh -F /dev/null -o BatchMode=yes'

repo="/home/valentin/git/github/obsidian-vault"
lock="/home/valentin/.pi/agent/.obsidian-vault-backup.lock"

exec 9>"$lock"
flock -n 9 || exit 0

cd "$repo"
git rev-parse --is-inside-work-tree >/dev/null
branch="$(git branch --show-current)"
if [[ -z "$branch" ]]; then
  printf 'Obsidian vault backup: detached HEAD; refusing to push.\n' >&2
  exit 1
fi

git pull --quiet --rebase --autostash origin "$branch"
git add -A -- .
committed=0
if ! git diff --cached --quiet; then
  git commit --quiet -m "Save Obsidian vault ($(date -Is))"
  committed=1
fi
git push --quiet origin "$branch"
if (( committed )); then
  printf 'Obsidian vault backup: committed and pushed on %s.\n' "$branch"
fi
