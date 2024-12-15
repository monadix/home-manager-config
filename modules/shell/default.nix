{ ... }:
{
  programs = {
    nushell = {
      enable = true;
      configFile.source = ./config.nu;
      envFile.source = ./env.nu;
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
}
