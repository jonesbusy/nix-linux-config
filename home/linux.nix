{ ... }:

{
  home.username = "valentin";
  home.homeDirectory = "/home/valentin";

  # Compatibility baseline for this Home Manager configuration.
  # This is not the Nixpkgs version and should generally stay fixed later.
  home.stateVersion = "26.05";

  programs.zsh.shellAliases = {
    k = "kubectl";
    docker = "podman";
  };

  home.sessionPath = [ "/usr/local/bin" ];

  home.sessionVariables = {
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/run/user/1000/podman/podman.sock";
  };
}
