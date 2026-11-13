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
      "project-env/tap"
      "salaboy/tap"
      "updatecli/updatecli"
    ];
    brews = [
      "jenkins-infra/tap/jv"
      "pyenv"
      "project-env/tap/project-env-cli"
      "salaboy/tap/skills-oci"
    ];
    ensureCompiler = false;
  };
}
