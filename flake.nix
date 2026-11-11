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

    nix-agents-home = {
      url = "github:jonesbusy/nix-agents-home";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    hermes-labs-plugins = {
      url = "github:NousResearch/hermes-labs-plugins/main";
      flake = false;
    };

    nix-agents-skills = {
      url = "github:jonesbusy/nix-agents-skills";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-linuxbrew,
      hermes-labs-plugins,
      nix-agents-skills,
      nix-agents-home,
      ...
    }:
    let
      linuxSystem = "x86_64-linux";
      pkgs = import nixpkgs {
        system = linuxSystem;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "sonarqube-cli"
            "terraform"
          ];
      };
      ubuntuK3sConfig = pkgs.writeText "k3s-config.yaml" (builtins.readFile ./ubuntu/k3s/config.yaml);
      ubuntuK3sService = import ./ubuntu/k3s/service.nix { inherit pkgs; };
    in
    {
      formatter.${linuxSystem} = pkgs.nixfmt-tree;

      packages.${linuxSystem} = {
        k3s-ubuntu-config = ubuntuK3sConfig;
        k3s-ubuntu-service = ubuntuK3sService;
      };

      homeConfigurations.valentin = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit hermes-labs-plugins;
          hermes-agent = nix-agents-home.inputs.hermes-agent;
        };
        modules = [
          ./home.nix
          nix-agents-skills.homeManagerModules.default
          nix-agents-home.homeManagerModules.default
          ./home/agents/pi.nix
          ./home/agents/hermes.nix
          ./home/agents/opencode.nix
          ./home/linux.nix
          nix-linuxbrew.homeManagerModules.default
          ./home/linuxbrew.nix
        ];
      };
    };
}
