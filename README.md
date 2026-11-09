# nix-linux-config

[![Nix validation](https://github.com/jonesbusy/nix-linux-config/actions/workflows/nix-validation.yml/badge.svg)](https://github.com/jonesbusy/nix-linux-config/actions/workflows/nix-validation.yml)

A Nix flake that manages my Linux workstation user environment with standalone [Home Manager](https://github.com/nix-community/home-manager). It configures `$HOME`, not the operating system, so activation never needs `sudo`.

## What's inside

- **Shell**: Zsh with Oh My Zsh, a custom Git prompt, and direnv
- **Tools from Nix**: Temurin JDK 25, JBang, Node.js, `gh`, Ansible, SOPS, age, Kustomize, Podman, k3s
- **Tools from Linuxbrew**: Kubernetes, Flux, Helm, Terraform/OpenTofu, OCI tooling, Maven, Renovate, and more (see [`home/linuxbrew.nix`](home/linuxbrew.nix))
- **Containers**: rootless Podman as a drop-in for `docker`, wired for Testcontainers
- **AI agents**: Pi, Hermes Agent, and OpenCode via [`nix-agents-home`](https://github.com/jonesbusy/nix-agents-home), with my settings kept in this repository
- **Agent skills**: shared skill selections via [`nix-agents-skills`](https://github.com/jonesbusy/nix-agents-skills)

## Getting started

### Requirements

- Nix with flakes enabled
- Git

If flakes are not enabled yet, add this line to `~/.config/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

> [!IMPORTANT]
> The configuration is written for user `valentin` (`/home/valentin`) with Linuxbrew at `/home/linuxbrew/.linuxbrew`. Change `home/linux.nix` and `home/linuxbrew.nix` before activating on another account.

### Install

```sh
git clone git@github.com:jonesbusy/nix-linux-config.git ~/nix-linux-config
cd ~/nix-linux-config
nix run github:nix-community/home-manager/master -- switch --flake .
```

Open a new terminal to load the Zsh configuration.

> [!NOTE]
> Home Manager renames conflicting files with a `.bak` suffix. Review them before deleting.

### Update

```sh
home-manager switch --flake .
```

To list or roll back generations:

```sh
home-manager generations
home-manager switch --rollback
```

### Optional: k3s system service

The k3s server needs root, so it sits outside Home Manager. [`ubuntu/k3s/apply.sh`](ubuntu/k3s/apply.sh) builds the config and systemd unit from the flake and installs them with `sudo`:

```sh
ubuntu/k3s/apply.sh
```

## Repository layout

```
.
├── flake.nix          # Inputs and the homeConfigurations.valentin output
├── home.nix           # Shell, CLI packages, session variables
├── home/
│   ├── linux.nix      # User, Podman, k3s client settings
│   ├── linuxbrew.nix  # Brew taps and formulas
│   └── agents/        # Links agent config files into $HOME
├── pi/ hermes/ opencode/   # Agent configuration files
├── tests/skills.nix   # Assertions on the selected agent skills
└── ubuntu/k3s/        # Opt-in system-level k3s setup
```

## Validate changes

Nix only sees files Git tracks, so stage new or changed files first. Then run:

```sh
nix fmt -- --ci
nix eval --impure --file tests/skills.nix
nix flake check --no-build
nix build --no-link .#homeConfigurations.valentin.activationPackage
```

CI runs the same checks on every push and pull request, plus the [`prek`](https://github.com/j178/prek) hooks in `.pre-commit-config.yaml` (formatting and `gitleaks`).

> [!CAUTION]
> Never commit credentials or private agent state.
