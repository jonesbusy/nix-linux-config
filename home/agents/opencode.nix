{ opencode, skillsModule }:
{ pkgs, ... }:
let
  opencodePackage = opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  # shortcut: v2.2.6 has an incorrect upstream node_modules hash; remove when upgrading to a release with a corrected hash.
  package =
    if opencodePackage.version == "2.2.6+dc2ffcf" then
      opencodePackage.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs (_: {
          outputHash = "sha256-s8XswivimwgzG0wMleHee5zliDKd+UC84eAvBvzr6cI=";
        });
      })
    else
      opencodePackage;
in
{
  imports = [ skillsModule ];

  programs.opencode = {
    enable = true;
    inherit package;
  };

  home.file.".config/opencode/opencode.json".source = ../../opencode/opencode.json;
}
