{
  description = "Chell's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/25.11";

    nixpkgs-master.url = "github:NixOS/nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree"; 
  };

  outputs = { 
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-master,
    home-manager,
    nix-vscode-extensions,
    sops-nix,
    import-tree,
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

      isSpecific = pkgs.lib.hasInfix ".thinkpad.";
    in {
      homeConfigurations = {
        generic = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [ 
            ./home.nix 
            (import-tree.filterNot isSpecific ./modules)
          ];

          extraSpecialArgs = {
            inherit system pkgsStable pkgsMaster nix-vscode-extensions sops-nix;
          };
        };

        thinkpad = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home.nix
            (import-tree ./modules)
          ];

          extraSpecialArgs = {
            inherit system pkgsStable pkgsMaster nix-vscode-extensions sops-nix;
          };
        };
      };
    };
}
