{ config
, 
... }:
{
  services.flameshot = {
    enable = true;
    
    settings = {
      General = {
        savePath = "${config.home.homeDirectory}/Pictures/Screenshots";
        savePathFixed = true;

        uiColor = "#FFFFFF";
        contrastUiColor = "#000000";

        filenamePattern = "%F_%T";
      };
    };
  };
}
