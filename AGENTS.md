# AGENTS.md

Nix flake for a standalone Home Manager setup on Linux (`x86_64-linux`), user `valentin`.

## Scope

- Keep changes inside the existing module layout (`home.nix`, `home/`). Do not add macOS support.
- System-level Ubuntu configuration lives only in `ubuntu/` and is applied by hand with `ubuntu/k3s/apply.sh`. Do not add more unless asked.
- Work on `main` unless the user asks for a branch or worktree.
- Use `superpowers` skills only when asked or for very complex tasks.

## Where things live

| Change | Edit |
| --- | --- |
| Shell, CLI packages, session variables | `home.nix` |
| Podman, k3s client, Linux-only settings | `home/linux.nix` |
| Linuxbrew taps and formulas | `home/linuxbrew.nix` |
| Pi, Hermes Agent, OpenCode settings | `pi/`, `hermes/`, `opencode/` (linked by `home/agents/*.nix`) |
| Reusable agent Home Manager modules | upstream `nix-agents-home` flake, not here |
| Skill sources and selections | upstream `nix-agents-skills` flake, not here |

When a `flake.lock` update changes skill selections, update the expected names in `tests/skills.nix`.

Never commit credentials or private agent state. `gitleaks` runs as a pre-commit hook.

## Validate

Nix only sees files Git tracks, so stage new or changed files first. Staging is not permission to commit.

```sh
nix fmt -- --ci
nix eval --impure --file tests/skills.nix
nix flake check --no-build
nix build --no-link .#homeConfigurations.valentin.activationPackage
```

CI (`.github/workflows/nix-validation.yml`) runs the same steps plus `prek`.

Do not run `home-manager switch`, `ubuntu/k3s/apply.sh`, or anything else that changes the user's installed tools unless explicitly asked.
