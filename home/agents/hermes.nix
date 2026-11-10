{
  hermes-agent,
  hermes-labs-plugins,
  lib,
  pkgs,
  ...
}:
let
  hermesPackages = hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
  pmNames = builtins.filter (name: lib.hasPrefix "pm-" name) (builtins.attrNames hermesPackages);
  pmPackages = lib.listToAttrs (
    map (
      name:
      let
        package = hermesPackages.${name};
      in
      lib.nameValuePair (lib.removePrefix "pm-" name) (
        package.overrideAttrs (old: {
          # shortcut: uses Patchelf 0.19.2 for all Hermes PM artifacts, remove after upstream fixes its 0.15.2 mismatch
          nativeBuildInputs = [
            pkgs.patchelfUnstable
          ]
          ++ builtins.filter (input: (input.pname or "") != "patchelf") (old.nativeBuildInputs or [ ]);
        })
      )
    ) pmNames
  );
  hermesPackage = hermesPackages.default.override {
    pmPackages = pmPackages // {
      node = pkgs.nodejs_26;
    };
  };
in
{
  programs.hermes-agent.desktop.enable = false;
  programs.hermes-agent.package = lib.mkForce hermesPackage;

  home.file = {
    ".hermes/config.yaml".source = ../../hermes/config.yaml;
    ".hermes/plugins/github-copilot".source = "${hermes-labs-plugins}/github-copilot";
  };
}
