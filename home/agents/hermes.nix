{ hermes-labs-plugins, ... }:
{
  programs.hermes-agent.desktop.enable = false;

  home.file = {
    ".hermes/config.yaml".source = ../../hermes/config.yaml;
    ".hermes/plugins/github-copilot".source = "${hermes-labs-plugins}/github-copilot";
  };

}
