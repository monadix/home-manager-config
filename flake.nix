{
  description = "Chell's Home Manager configuration";

  inputs = {
    assets.url = "github:monadix/assets";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/25.11";

    nixpkgs-master.url = "github:NixOS/nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree"; 

    telescope-orgmode = {
      url = "github:nvim-orgmode/telescope-orgmode.nvim";
      flake = false;
    };
  };

  outputs = { 
    assets,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-master,
    home-manager,
    sops-nix,
    import-tree,
    telescope-orgmode,
    ... 
  }:
    let
      system = "x86_64-linux";

      importPkgsDefaultArgs = p: import p {
        inherit system;

        config.allowUnfree = true;
      };

      pkgs = importPkgsDefaultArgs nixpkgs;
      pkgsStable = importPkgsDefaultArgs nixpkgs-stable;
      pkgsMaster = importPkgsDefaultArgs nixpkgs-master;

      mkHost = host: {
        imports = [
          (import-tree ./common)
          sops-nix.homeManagerModules.sops
          (import-tree host)
        ];

        _module.args = {
          inherit
            system
            assets
            pkgsStable
            pkgsMaster
            telescope-orgmode;
        };
      };

      homeModules = {
        conputer = mkHost ./hosts/conputer;
        naumbuk = mkHost ./hosts/naumbuk;
        ugly-rod = mkHost ./hosts/ugly-rod;
        MDR024 = mkHost ./hosts/MDR024;
      };

      homeConfigurationWith = module: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [ module ];

        extraSpecialArgs = {
          inherit
            system
            assets
            pkgsStable
            pkgsMaster
            telescope-orgmode;
        };
      };
    in {
      inherit homeModules;

      homeConfigurations = builtins.mapAttrs
        (_: homeConfigurationWith)
        homeModules;
    };
}
