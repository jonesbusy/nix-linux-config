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
      "crane"
      "diffoscope"
      "fluxcd/tap/flux"
      "helm"
      "hashicorp/tap/terraform"
      "herdr"
      "kubernetes-cli"
      "maven"
      "notation"
      "opentofu"
      "oras"
      "plugin-modernizer"
      "prek"
      "renovate"
      "rtk"
      "salaboy/tap/skills-oci"
      "skopeo"
      "sofka"
      "sonar-scanner"
      "step"
      "updatecli/updatecli/updatecli"
      "uv"
    ];
    ensureCompiler = false;
  };
}
