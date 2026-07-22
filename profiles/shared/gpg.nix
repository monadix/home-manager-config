{ 
  pkgs,
  ... 
}:
{
  services.gpg-agent = {
    enable = true;
    enableNushellIntegration = true;

    pinentry.package = pkgs.pinentry-gtk2;
  };

  programs.gpg.enable = true;
}
