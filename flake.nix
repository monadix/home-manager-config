{
  description = "Chell's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/24.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mur = {
      url = "github:monadix/mur";

      inputs.stable.follows = "nixpkgs-stable";
    };
  };

  outputs = { nixpkgs, nixpkgs-stable, home-manager, nix-vscode-extensions, mur, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgsStable = nixpkgs-stable.legacyPackages.${system};
      vscode-extensions = nix-vscode-extensions.extensions."${system}";
      murPkgs = mur.packages.${system};
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
          inherit vscode-extensions pkgsStable murPkgs;
        };
      };
    };
}
