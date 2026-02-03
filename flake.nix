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
  };

  outputs = { 
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-master,
    home-manager,
    nix-vscode-extensions,
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
    in {
      homeConfigurations.chell = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [ 
          ./home.nix 
          ./modules
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit system pkgsStable pkgsMaster nix-vscode-extensions;
        };
      };
    };
}
