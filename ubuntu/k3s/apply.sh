#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
config="$(nix build --no-link --print-out-paths "$repo_root#k3s-ubuntu-config")"
service="$(nix build --no-link --print-out-paths "$repo_root#k3s-ubuntu-service")"

sudo install -D -o root -g root -m 0644 "$config" /etc/rancher/k3s/config.yaml
sudo install -D -o root -g root -m 0644 "$service" /etc/systemd/system/k3s.service
sudo systemctl daemon-reload
sudo systemctl enable k3s
if sudo systemctl is-active --quiet k3s; then
  sudo systemctl restart k3s
else
  sudo systemctl start k3s
fi
