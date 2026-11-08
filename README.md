# Linux workstation configuration

A Nix flake for a standalone Home Manager setup on Linux (`x86_64-linux`). It manages your user environment, not Ubuntu itself.

## Requirements

- Nix with `nix-command` and `flakes` enabled
- Git

If flakes are not enabled, add this to `~/.config/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

## Install or update

Clone the repository and review the host settings before activation. The configuration currently uses the `valentin` account, `/home/valentin`, and Linuxbrew at `/home/linuxbrew/.linuxbrew`.

```sh
git clone git@github.com:jonesbusy/nix-linux-config.git "$HOME/nix-linux-config"
cd "$HOME/nix-linux-config"
```

For the first activation, run Home Manager from the flake:

```sh
nix run github:nix-community/home-manager/master -- switch --flake .
```

For later changes:

```sh
home-manager switch --flake .
```

Home Manager moves conflicting files aside with the `.bak` suffix, as configured in `home.nix`. Review those backups before removing them. Activation changes your home directory; it does not require `sudo` or configure Ubuntu. Open a new terminal to load the Zsh configuration.

To inspect or roll back generations:

```sh
home-manager generations
home-manager switch --rollback
```

## What it manages

- Zsh, command-line tools, and Linuxbrew formulas
- Pi, Hermes Agent, and OpenCode packages via `nix-agents-home`, with personal configuration kept here
- Shared agent skills via `nix-agents-skills`
- Linux-specific settings

Edit the source files here; Home Manager links them into your home directory. Do not commit credentials.

## Validate changes

Stage new or changed files before running flake commands so Nix includes them. Then run:

```sh
nix fmt -- --ci
nix eval --impure --file tests/skills.nix
nix flake check --no-build
nix build --no-link .#homeConfigurations.valentin.activationPackage
```
