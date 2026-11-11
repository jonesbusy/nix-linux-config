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
      "awscli"
      "cosign"
      "diffoscope"
      "fluxcd/tap/flux"
      "oras"
      "plugin-modernizer"
      "prek"
      "salaboy/tap/skills-oci"
      "uv"
    ];
    ensureCompiler = false;
  };
}
