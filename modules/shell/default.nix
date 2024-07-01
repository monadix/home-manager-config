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
  };
}
