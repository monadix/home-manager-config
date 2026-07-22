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
  };

  outputs = { 
    assets,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-master,
    home-manager,
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

      profileWith = modules: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          (import-tree ./profiles/shared)
        ] ++ builtins.map import-tree modules;

        extraSpecialArgs = {
          inherit system assets pkgsStable pkgsMaster sops-nix;
        };
      };
    in {
      homeConfigurations = {
        default = profileWith [ ./profiles/default ];

        naumbuk = profileWith [ ./profiles/naumbuk ];
      };
    };
}
