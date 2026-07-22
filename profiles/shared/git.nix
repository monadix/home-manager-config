{ ... }:
{
  programs = {
    git = {
      enable = true;

      settings.user = {
        name = "monadix";
        email = "arsenijalfeev@gmail.com";
      };

      signing.format = null;
    };
    
    gh.enable = true;
  };
}
