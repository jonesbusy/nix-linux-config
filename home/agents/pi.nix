{ pkgs, qmd, ... }:
let
  qmdPackage = qmd.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (_: {
    # Upstream still substitutes glibc from the old wrapper, but qmd no longer adds it.
    postFixup = "";
  });
in
{
  programs.qmd = {
    enable = true;
    package = qmdPackage;
  };

  home.file = {
    ".pi/agent/mcp.json".source = ../../pi/mcp.json;
    ".pi/agent/settings.json".source = ../../pi/settings.json;
    ".pi/agent/extensions/rtk.ts".source = ../../pi/extensions/rtk.ts;
    ".pi/agent/extensions/exit.ts".source = ../../pi/extensions/exit.ts;
    ".pi/agent/prompts/agent-md-refactor.md".source = ../../pi/prompts/agent-md-refactor.md;
  };
}
