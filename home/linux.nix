{ lib, pkgs, ... }:

{
  home.username = "valentin";
  home.homeDirectory = "/home/valentin";

  # Compatibility baseline for this Home Manager configuration.
  # This is not the Nixpkgs version and should generally stay fixed later.
  home.stateVersion = "26.05";

  home.packages = with pkgs; [ podman k3s ];

  xdg.configFile."containers/registries.conf".text = ''
    unqualified-search-registries = ["docker.io"]
    short-name-mode = "disabled"
  '';
  xdg.configFile."containers/registries.conf.d/shortnames.conf".text = "";
  xdg.configFile."containers/storage.conf".text = ''
    [storage]
    runroot = "$XDG_RUNTIME_DIR/containers"
    rootless_storage_path = "$HOME/.local/share/containers/storage"
  '';

  home.file.".config/systemd/user/podman.service".source = "${pkgs.podman}/share/systemd/user/podman.service";
  home.file.".config/systemd/user/podman.socket".source = "${pkgs.podman}/share/systemd/user/podman.socket";

  programs.zsh.shellAliases = {
    k = "kubectl";
    docker = "podman";
  };

  home.sessionPath = [ "/usr/local/bin" ];

  programs.zsh.initContent = lib.mkBefore ''
    if [[ -z "$KUBECONFIG" ]]; then
      export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
    fi
  '';

  home.sessionVariables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/run/user/1000/podman/podman.sock";
  };
}
