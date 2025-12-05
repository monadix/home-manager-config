{ ... }:
{
  programs = {
    git = {
      enable = true;

      settings.user = {
        name = "monadix";
        email = "arsenijalfeev@gmail.com";
      };
    };
    
    gh.enable = true;
  };
}
