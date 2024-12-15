{ ... }:
{
  programs = {
    nushell = {
      enable = true;
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
