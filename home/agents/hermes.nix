{
  hermes-agent,
  hermes-labs-plugins,
}:
{ lib, pkgs, ... }:
let
  hermesPackages = hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
  pmNames = builtins.filter (name: lib.hasPrefix "pm-" name) (builtins.attrNames hermesPackages);
  pmPackages = lib.listToAttrs (
    map (name: lib.nameValuePair (lib.removePrefix "pm-" name) hermesPackages.${name}) pmNames
  );
  hermesPackage = hermesPackages.default.override {
    pmPackages = pmPackages // {
      node = pkgs.nodejs_26;
    };
  };
in
{
  imports = [ hermes-agent.homeManagerModules.default ];

  programs.hermes-agent = {
    enable = true;
    desktop.enable = false;
    package = hermesPackage;
  };

  home.file = {
    ".hermes/config.yaml".source = ../../hermes/config.yaml;
    ".hermes/plugins/github-copilot".source = "${hermes-labs-plugins}/github-copilot";
  };

  # Hermes stores auth, sessions, and other private state under this directory.
  home.activation.secureHermesHomeDirectory = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD chmod 700 "$HOME/.hermes"
    if [ ! -e "$HOME/.hermes/.env" ]; then
      $DRY_RUN_CMD touch "$HOME/.hermes/.env"
      $DRY_RUN_CMD chmod 600 "$HOME/.hermes/.env"
    fi
  '';
}
