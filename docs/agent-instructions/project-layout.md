# Scope and file layout

- Keep changes inside the existing module layout (`home.nix`, `home/`). Do not add macOS support.
- System-level Ubuntu configuration lives only in `ubuntu/` and is applied by hand with `ubuntu/k3s/apply.sh`. Do not add more unless asked.
- Use `superpowers` skills only when asked or for very complex tasks.

| Change | Edit |
| --- | --- |
| Shell, CLI packages, session variables | `home.nix` |
| Podman, k3s client, Linux-only settings | `home/linux.nix` |
| Linuxbrew taps and formulas | `home/linuxbrew.nix` |
| Pi, Hermes Agent, OpenCode settings | `pi/`, `hermes/`, `opencode/` (linked by `home/agents/*.nix`) |
| Reusable agent Home Manager modules | upstream `nix-agents-home` flake, not here |
| Skill sources and selections | upstream `nix-agents-skills` flake, not here |

When a `flake.lock` update changes skill selections, update the expected names in `tests/skills.nix`.
