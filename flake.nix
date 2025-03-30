{
  description = "Chell's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/24.05";

    nixpkgs-cursor-47-8.url = "github:NixOS/nixpkgs/pull/393609/head";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, nixpkgs-stable, nixpkgs-cursor-47-8, home-manager, nix-vscode-extensions, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system}.extend (final: prev: {
        code-cursor = pkgsCursor-47-8.code-cursor;
      });
      pkgsStable = nixpkgs-stable.legacyPackages.${system};
      pkgsCursor-47-8 = import nixpkgs-cursor-47-8 {
        inherit system;
        config.allowUnfree = true;
      };
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
          inherit nix-vscode-extensions pkgsStable;
        };
      };
    };
}
