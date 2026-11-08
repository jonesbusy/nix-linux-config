{ ... }:
{
  home.file = {
    ".pi/agent/mcp.json".source = ../../pi/mcp.json;
    ".pi/agent/settings.json".source = ../../pi/settings.json;
    ".pi/agent/extensions/rtk.ts".source = ../../pi/extensions/rtk.ts;
  };
}
