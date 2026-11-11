{ ... }:

{
  # Linuxbrew is a Linux-only layer; the shared CLI packages are managed by Nix.
  programs.linuxbrew = {
    enable = true;
    brewPrefix = "/home/linuxbrew/.linuxbrew";
    taps = [
      "fluxcd/tap"
      "hashicorp/tap"
      "jenkins-infra/tap"
      "salaboy/tap"
      "updatecli/updatecli"
    ];
    brews = [
      "salaboy/tap/skills-oci"
    ];
    ensureCompiler = false;
  };
}
