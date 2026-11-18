{
  hermes-agent,
  hermes-labs-plugins,
  lib,
  pkgs,
  googleWorkspaceCli,
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
  hermesPmTools = [
    "ffmpeg"
    "node"
    "npm"
    "pnpm"
    "ripgrep"
  ];
  hermesLock = builtins.fromJSON (builtins.readFile "${hermes-agent.outPath}/pm/lock.json");
  hermesTarget = "linux-${if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}";
  hermesCopilotSource = pkgs.writeText "hermes-copilot-source" "${hermes-labs-plugins}/github-copilot";
  hermesPmFacts = pkgs.writeText "hermes-pm-facts.json" (
    builtins.toJSON {
      schema = 1;
      packages = lib.listToAttrs (
        map (name: {
          name = name;
          value = {
            entry = name;
            version = hermesLock.packages.${name}.version;
            target = hermesTarget;
            artifacts = map (artifact: artifact.sha256) (
              let
                pinned =
                  hermesLock.packages.${name}.artifacts.${hermesTarget} or hermesLock.packages.${name}.artifacts.any;
              in
              if builtins.isList pinned then pinned else [ pinned ]
            );
            env.PATH = [ "{{store}}/${name}/bin" ];
          };
        }) hermesPmTools
      );
    }
  );
  hermesPackage =
    (hermesPackages.default.override {
      inherit pmPackages;
    }).overrideAttrs
      (old: {
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
  home.packages = [ googleWorkspaceCli ];

  programs.hermes-agent.desktop.enable = false;
  programs.hermes-agent.package = lib.mkForce hermesPackage;

  # The Nix store is immutable, so let Home Manager own the gateway unit
  # instead of using `hermes gateway install`'s mutable launcher setup.
  services.hermes-agent = {
    enable = true;
    gateway.enable = true;
    package = lib.mkForce hermesPackage;
    configFile = ../../hermes/config.yaml;
  };

  home.activation.hermesAgentSkillsRsyncCompatibility =
    (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rsync() {
        local -a adjusted=()
        local arg
        for arg in "$@"; do
          if [[ "$arg" == "--" ]]; then
            adjusted+=(--no-owner --no-group --)
          else
            adjusted+=("$arg")
          fi
        done
        command ${pkgs.rsync}/bin/rsync "''${adjusted[@]}"
      }
      export -f rsync
    '')
    // {
      before = [ "agent-skills" ];
    };

  home.activation.hermesAgentSkillsRsyncCompatibilityCleanup =
    lib.hm.dag.entryAfter [ "agent-skills" ]
      ''
        unset -f rsync
      '';

  systemd.user.services.hermes-agent.Service.Environment = lib.mkAfter [
    "HERMES_RUNTIME_DIR=${hermesPackage}/tools"
    "HERMES_PRIVATE_DRIFT_PYTHON=${hermesPackage.hermesVenv}/bin/python3"
    "HERMES_PRIVATE_DRIFT_BIN_PATH=${
      lib.makeBinPath [
        pkgs.git
        pkgs.gh
      ]
    }"
  ];

  home.sessionVariables = {
    HERMES_RUNTIME_DIR = "${hermesPackage}/tools";
    WIKI_PATH = "/home/valentin/git/github/obsidian-vault/personal";
    OBSIDIAN_VAULT_PATH = "/home/valentin/git/github/obsidian-vault/personal";
  };

  home.activation.hermesCopilotPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    plugin="$HOME/.hermes/plugins/github-copilot"
    source="${hermes-labs-plugins}/github-copilot"
    marker="${hermesCopilotSource}"
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.hermes/plugins"
    if [ -L "$plugin" ]; then ${pkgs.coreutils}/bin/rm "$plugin"; fi
    if [ ! -d "$plugin" ] || ! ${pkgs.diffutils}/bin/cmp -s "$marker" "$plugin/.nix-source"; then
      if [ -e "$plugin" ] && [ ! -f "$plugin/.nix-source" ]; then
        echo "Refusing to replace unmanaged Hermes plugin directory: $plugin" >&2
        exit 1
      fi
      stage=$(${pkgs.coreutils}/bin/mktemp -d "$HOME/.hermes/plugins/.github-copilot.XXXXXX")
      ${pkgs.coreutils}/bin/cp -R "$source/." "$stage/"
      ${pkgs.findutils}/bin/find "$stage" -type d -exec ${pkgs.coreutils}/bin/chmod u+rwx {} +
      ${pkgs.coreutils}/bin/cp "$marker" "$stage/.nix-source"
      if [ -d "$plugin" ]; then
        ${pkgs.findutils}/bin/find "$plugin" -type d -exec ${pkgs.coreutils}/bin/chmod u+rwx {} +
        ${pkgs.coreutils}/bin/rm -rf "$plugin"
      fi
      ${pkgs.coreutils}/bin/mv "$stage" "$plugin"
    fi
  '';

  home.activation.hermesBackupScripts = lib.hm.dag.entryAfter [ "hermesCopilotPlugin" ] ''
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.hermes/scripts"
    ${pkgs.coreutils}/bin/rm -f "$HOME/.hermes/scripts/pi-memory-hourly-backup.sh" "$HOME/.hermes/scripts/obsidian-vault-hourly-backup.sh"
    for script in pi-memory-backup.sh obsidian-vault-backup.sh hermes-private-drift-backup.sh; do
      source="${../../hermes/scripts}/$script"
      target="$HOME/.hermes/scripts/$script"
      if ! ${pkgs.diffutils}/bin/cmp -s "$source" "$target"; then
        ${pkgs.coreutils}/bin/install -m 0755 "$source" "$target"
      fi
    done
  '';

  home.activation.hermesCronJobs = lib.hm.dag.entryAfter [ "hermesBackupScripts" ] ''
    HERMES_HOME="$HOME/.hermes" ${hermesPackage.hermesVenv}/bin/python3 \
      ${../../hermes/scripts/sync-cron-jobs.py} ${../../hermes/cron/jobs.json}
  '';

  home.file = {
    ".hermes/SOUL.md".source = ../../hermes/SOUL.md;
  };
}
