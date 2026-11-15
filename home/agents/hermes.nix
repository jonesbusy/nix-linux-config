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
  hermesPmTools = [ "ffmpeg" "node" "npm" "pnpm" "ripgrep" ];
  hermesLock = builtins.fromJSON (builtins.readFile "${hermes-agent.outPath}/pm/lock.json");
  hermesTarget = "linux-${if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}";
  hermesPmFacts = pkgs.writeText "hermes-pm-facts.json" (builtins.toJSON {
    schema = 1;
    packages = lib.listToAttrs (map (name: {
      name = name;
      value = {
        entry = name;
        version = hermesLock.packages.${name}.version;
        target = hermesTarget;
        artifacts = map (artifact: artifact.sha256) (
          let
            pinned = hermesLock.packages.${name}.artifacts.${hermesTarget}
              or hermesLock.packages.${name}.artifacts.any;
          in
          if builtins.isList pinned then pinned else [ pinned ]
        );
        env.PATH = [ "{{store}}/${name}/bin" ];
      };
    }) hermesPmTools);
  });
  hermesPackage = (hermesPackages.default.override {
    inherit pmPackages;
  }).overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      mkdir -p "$out/tools"
      ${lib.concatMapStringsSep "\n" (name: ''
        ln -s ${pmPackages.${name}} "$out/tools/${name}"
      '') hermesPmTools}
      cp ${hermesPmFacts} "$out/tools/facts.json"
    '';
  });
in
{
  programs.hermes-agent.desktop.enable = false;
  programs.hermes-agent.package = lib.mkForce hermesPackage;
  home.sessionVariables.HERMES_RUNTIME_DIR = "${hermesPackage}/tools";

  home.file = {
    ".hermes/config.yaml".source = ../../hermes/config.yaml;
    ".hermes/plugins/github-copilot".source = "${hermes-labs-plugins}/github-copilot";
  };
}
