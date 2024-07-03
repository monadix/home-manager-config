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

        showHelp = false;
        showSidePanelButton = false;

        filenamePattern = "%F_%T";
      };
    };
  };
}
