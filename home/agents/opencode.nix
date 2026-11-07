{ nixpkgs, skillsModule }:
{ pkgs, ... }:
let
  # shortcut: locked nixpkgs has a stale 2.2.5 Linux hash; remove when the lock includes upstream's correction.
  opencode = nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode.overrideAttrs (old: {
    node_modules = old.node_modules.overrideAttrs (_: {
      outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
    });
  });
in
{
  imports = [ skillsModule ];

  home.packages = [ opencode ];
  home.file.".config/opencode/opencode.json".source = ../../opencode/opencode.json;
}
