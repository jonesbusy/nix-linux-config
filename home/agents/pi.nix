{ pkgs, qmd, ... }:
let
  qmdPackage = qmd.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    # Avoid exposing Nix glibc to host commands through qmd's LD_LIBRARY_PATH.
    postFixup = (old.postFixup or "") + ''
      substituteInPlace $out/bin/qmd \
        --replace-fail "${pkgs.stdenv.cc.libc.out}/lib:" ""
    '';
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
  };
}
