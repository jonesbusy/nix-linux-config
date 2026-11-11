{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  # Command-line tools for the Linux Home Manager configuration.
  home.packages = [
    pkgs.nodejs_26
    pkgs.temurin-bin-25
    (pkgs.jbang.override { jdk = pkgs.temurin-bin-25; })
    pkgs.gh
    pkgs.ansible
    pkgs.sops
    pkgs.age
    pkgs.kustomize
    pkgs.git
    pkgs.crane
    pkgs.gitleaks
    pkgs.herdr
    (pkgs.lib.hiPrio pkgs.kubectl)
    pkgs.kubernetes-helm
    pkgs.maven
    pkgs.notation
    pkgs.opentofu
    pkgs.renovate
    pkgs.rtk
    pkgs.skopeo
    pkgs.step-cli
    pkgs.terraform
    pkgs.updatecli
  ];

  home.backupFileExtension = "bak";

  home.file.".git-prompt.sh" = {
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh";
      hash = "sha256-VdOMa2OFFcKKdDO58ax3VPiYoyIRGGgfH6SyG2Dt1ZY=";
    };
    force = true;
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "flazz";
      plugins = [
        "git"
        "virtualenvwrapper"
      ];
    };

    initContent = ''
      # Expose GitHub CLI credentials to programs that require GH_TOKEN.
      if [[ -z "$GH_TOKEN" ]] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        GH_TOKEN="$(gh auth token 2>/dev/null)" && export GH_TOKEN
      fi

      # Clear stale SDKMAN state inherited from already-running parent shells.
      unset SDKMAN_DIR
      path=(''${path:#$HOME/.sdkman/*})

      # Prefer the Nix-managed JDK over any system Java on PATH.
      export JAVA_HOME="${pkgs.temurin-bin-25}"
      path=("${pkgs.temurin-bin-25}/bin" $path)

      # Restore the original custom prompt after Oh My Zsh loads its theme.
      if [[ -r "$HOME/.git-prompt.sh" ]]; then
        source "$HOME/.git-prompt.sh"
        setopt PROMPT_SUBST
        CARETCOLOR=magenta
        GIT_PS1_SHOWUPSTREAM=verbose
        GIT_PS1_SHOWDIRTYSTATE=1
        GIT_PS1_SHOWSTASHSTATE=1
        GIT_PS1_SHOWUNTRACKEDFILES=1
        GIT_PS1_SHOWCOLORHINTS=1
        PROMPT='%{''${fg[cyan]}%}%n@%m%{''${fg_bold[magenta]}%}:%{$reset_color%}%3~%{$fg_bold[cyan]%}$(__git_ps1 " (%s)") %{''${fg_bold[$CARETCOLOR]}%}$%{''${reset_color}%} '
        RPROMPT='%{$fg[white]%}[%?][%l][%*]%{$reset_color%}'
      fi
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    EDITOR = "vim";
    MAVEN_OPTS = "-Xms1024m";
    JAVA_HOME = "${pkgs.temurin-bin-25}";
    NIX_CONFIG = "experimental-features = nix-command flakes";
  };
}
