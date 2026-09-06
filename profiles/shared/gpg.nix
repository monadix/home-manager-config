{ 
  pkgs,
  ... 
}:
{
  services.gpg-agent = {
    enable = true;
    enableNushellIntegration = true;

    pinentry.package = pkgs.pinentry-gnome3;
  };

  programs.gpg.enable = true;
}
