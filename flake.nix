{
  description = "Home Manager configuration for Valentin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-linuxbrew = {
      url = "github:deepwatrcreatur/nix-linuxbrew";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    pi.url = "github:earendil-works/pi/v1.4.0";

    hermes-agent = {
      url = "github:NousResearch/hermes-agent/v0.23.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    hermes-labs-plugins = {
      url = "github:NousResearch/hermes-labs-plugins/main";
      flake = false;
    };

    aws-agent-toolkit = {
      url = "github:aws/agent-toolkit-for-aws";
      flake = false;
    };

    openai-skills = {
      url = "github:openai/skills";
      flake = false;
    };

    quarkus-skills = {
      url = "github:quarkusio/skills";
      flake = false;
    };

    awesome-copilot = {
      url = "github:github/awesome-copilot";
      flake = false;
    };

    jbang-agent-skills = {
      url = "github:jbangdev/agent-skills";
      flake = false;
    };

    softaworks-agent-toolkit = {
      url = "github:softaworks/agent-toolkit";
      flake = false;
    };

    agent-skills-nix = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nix-linuxbrew,
      pi,
      hermes-agent,
      hermes-labs-plugins,
      aws-agent-toolkit,
      openai-skills,
      quarkus-skills,
      awesome-copilot,
      jbang-agent-skills,
      softaworks-agent-toolkit,
      agent-skills-nix,
      ...
    }:
    let
      linuxSystem = "x86_64-linux";
      skillsModule = import ./home/agents/skills.nix {
        inherit
          agent-skills-nix
          aws-agent-toolkit
          nixpkgs
          openai-skills
          quarkus-skills
          awesome-copilot
          jbang-agent-skills
          softaworks-agent-toolkit
          ;
      };
      piModule = import ./home/agents/pi.nix { inherit pi skillsModule; };
      hermesModule = import ./home/agents/hermes.nix {
        inherit hermes-agent hermes-labs-plugins skillsModule;
      };
      opencodeModule = import ./home/agents/opencode.nix { inherit nixpkgs skillsModule; };
      homeManagerModules = {
        skills = skillsModule;
        pi = piModule;
        hermes = hermesModule;
        opencode = opencodeModule;
      };
    in
    {
      inherit homeManagerModules;

      homeConfigurations.valentin = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = linuxSystem; };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home.nix
          homeManagerModules.pi
          homeManagerModules.hermes
          homeManagerModules.opencode
          ./home/linux.nix
          nix-linuxbrew.homeManagerModules.default
          ./home/linuxbrew.nix
        ];
      };
    };
}
