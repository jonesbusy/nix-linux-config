# Linux workstation configuration

A Nix flake and standalone Home Manager setup for an Ubuntu Linux workstation (`x86_64-linux`). It manages user-level command-line tools, Zsh, AI coding agents, MCP configuration, and shared agent skills. It does not configure Ubuntu itself or manage `apt` packages.

## Requirements

- Nix with the `nix-command` and `flakes` experimental features
- Git

If flakes are not enabled, add this to `~/.config/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

## Install

Clone the repository and review the host-specific settings before activation. The checked-in configuration currently uses the `valentin` account, `/home/valentin`, and a Linuxbrew installation at `/home/linuxbrew/.linuxbrew`.

```sh
git clone git@github.com:jonesbusy/nix-linux-config.git "$HOME/nix-linux-config"
cd "$HOME/nix-linux-config"
```

Nix evaluates a Git checkout from its tracked files. Stage new or changed files before running flake commands so Nix includes them; staging does not commit them.

Check and build the configuration without activating it:

```sh
nix flake check --no-build
nix build --no-link .#homeConfigurations.valentin.activationPackage
```

For the first activation, run Home Manager from the flake's release line:

```sh
nix run github:nix-community/home-manager/master -- \
  switch -b hm-backup --flake .#valentin
```

The `-b hm-backup` option moves conflicting unmanaged files aside with that suffix. Review those backups before removing them. Activation manages files and installs tools in your home directory; it does not require `sudo` or replace Ubuntu. Open a new terminal to load the Zsh configuration.

For later changes:

```sh
home-manager switch -b hm-backup --flake .#valentin
```

To inspect or roll back Home Manager generations:

```sh
home-manager generations
home-manager switch --rollback
```

## What it manages

- **Shell and CLI tools:** Zsh, Oh My Zsh, direnv, Node.js 26, Temurin Java 25, JBang, GitHub CLI, Ansible, SOPS, age, and kustomize.
- **Linuxbrew:** Linux-only formulas declared in `home/linuxbrew.nix`; this module can run Homebrew's installer if it cannot find Homebrew at its configured prefix. Removing a formula from the declaration does not uninstall it.
- **Coding agents:** Pi, Hermes Agent (CLI only), and OpenCode, with checked-in configuration under `pi/`, `hermes/`, and `opencode/`.
- **Agent skills:** A shared catalog linked into `~/.agents/skills`, assembled from AWS, OpenAI, Quarkus, GitHub Awesome Copilot, JBang, and Softaworks sources.
- **Linux settings:** Host identity, Podman socket, aliases, and Linux-specific paths in `home/linux.nix`.

Pi, Hermes, and OpenCode configure GitHub MCP (`GH_TOKEN`) and two local JBang MCP servers (`quarkus-agent` and `huginn`). Pi and OpenCode also configure AWS MCP through the AWS CLI credential chain. Before first use of Huginn, trust its Maven Central origin once:

```sh
jbang trust add https://repo.maven.apache.org/maven2/eu/maveniverse/maven/huginn/
```

OpenCode also needs `GH_TOKEN` in the environment where it starts. Pi extensions run with your user permissions; review extension code before adding or updating packages.

The source files in this repository are authoritative for Home Manager-managed configuration. Edit them here rather than editing generated files in your home directory.

## Validate changes

The CI workflow runs these checks:

```sh
nix eval --impure --file tests/skills.nix
nix flake check --no-build
nix build --no-link .#homeConfigurations.valentin.activationPackage
```

The skill test checks selected upstream skills and their source paths. Pre-commit checks also validate Renovate configuration and fix common whitespace issues.

## Repository layout

| Path | Purpose |
| --- | --- |
| `flake.nix`, `flake.lock` | Pinned inputs, Home Manager configuration, and reusable modules |
| `home.nix`, `home/` | Shared and Linux-specific settings, agent modules, and skill selection |
| `pi/`, `hermes/`, `opencode/` | Agent configuration and the local Pi extension |
| `tests/skills.nix` | Assertions for the skill catalog |
| `.github/workflows/` | CI validation |

## Reuse the agent modules

The flake exports `homeManagerModules.pi`, `.hermes`, `.opencode`, and `.skills`. Import an agent module in another Home Manager configuration to install that agent and the shared skills catalog. Set the consuming user's identity and state version in that configuration; these modules do not import this repository's shell, host identity, or Linuxbrew setup.

```nix
home-manager.users.valentin = {
  imports = [ inputs.workstation.homeManagerModules.pi ];
  home.username = "valentin";
  home.homeDirectory = "/home/valentin";
  home.stateVersion = "26.05";
};
```

## Updating inputs and skills

`flake.lock` pins package and source revisions. Updating a branch name alone does not refresh those pins; update the lock and then switch Home Manager. For example, refresh the skill sources with:

```sh
nix flake update agent-skills-nix aws-agent-toolkit openai-skills quarkus-skills awesome-copilot jbang-agent-skills softaworks-agent-toolkit
home-manager switch -b hm-backup --flake .#valentin
```

The skill selection lives in `home/agents/skills.nix`. Pi and Hermes release tags are declared in `flake.nix`; update the relevant tag and lock input to change their versions.

## Credentials

Do not commit tokens, passwords, private keys, or other credentials. GitHub MCP configuration reads `GH_TOKEN` (the interactive Zsh setup can obtain it from `gh auth token`); AWS MCP uses the AWS CLI credential chain. Keep agent authentication and private state in their user-level locations, not in this repository.
