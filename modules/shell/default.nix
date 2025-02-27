{ ... }:
{
  programs = {
    nushell = {
      enable = true;
      configFile.source = ./config.nu;
    };

    carapace = {
      enable = true;
      enableNushellIntegration = true;
    };

    starship = {
      enable = true;
      settings.add_newline = true;
    };

    nix-your-shell = {
      enable = true;
      enableNushellIntegration = true;
    };
  };

  services = {
    pueue = {
      enable = true;
    };
  };

  home.file = {
    ".config/nushell/scripts" = {
      source = ./scripts;
      recursive = true;
    };
  };
}
