# AGENTS.md

Nix flake for a standalone Home Manager setup on Linux (`x86_64-linux`), user `valentin`.

## Universal rules

- Work on `main` unless the user asks for a branch or worktree.
- Never commit credentials or private agent state. `gitleaks` runs as a pre-commit hook.
- Do not run `home-manager switch`, `ubuntu/k3s/apply.sh`, or anything else that changes installed tools unless explicitly asked.

## Project guidance

- [Scope and file layout](docs/agent-instructions/project-layout.md)
- [Validation and upstream references](docs/agent-instructions/validation.md)
