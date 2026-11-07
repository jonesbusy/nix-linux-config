# Repository guidance

This repository is a Nix flake for a Linux (`x86_64-linux`) Home Manager setup. Keep changes consistent with the existing module structure; do not add macOS or system-level Ubuntu configuration unless requested.

## Workflow

- Work directly on `main` unless the user asks for a branch or worktree.

## Validate

- Stage new or modified files before flake evaluation; Nix reads Git checkout sources from tracked files. Staging is not permission to commit.
- Run `nix eval --impure --file tests/skills.nix`, `nix flake check --no-build`, and `nix build --no-link .#homeConfigurations.valentin.activationPackage` when relevant.
- Do not activate Home Manager or change the user's installed tools unless explicitly requested.

## Source of truth

- Edit tracked files under `home/`, `pi/`, `hermes/`, and `opencode/`; Home Manager links these into the user's home directory.
- Add or change skill selections in `home/agents/skills.nix` and update its assertions in `tests/skills.nix` when selection changes.
- Never add credentials or private agent state to the repository.
