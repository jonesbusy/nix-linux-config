# Validation and upstream references

## Upstream references

- [Hermes Nix packaging fix (#143332)](https://github.com/NousResearch/hermes-agent/pull/143332)
- [Patchelf LOAD-mapping fix (#672)](https://github.com/NixOS/patchelf/pull/672)

## Validate

Nix only sees files Git tracks, so stage new or changed files first. Staging is not permission to commit.

```sh
nix fmt -- --ci
nix eval --impure --file tests/skills.nix
nix eval --impure --file tests/agent-skills-rsync-activation.nix
nix flake check --no-build
nix build --no-link .#homeConfigurations.valentin.activationPackage
```

CI (`.github/workflows/nix-validation.yml`) runs the same steps plus `prek`.
