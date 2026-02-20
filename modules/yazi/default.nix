{ ... }:
{
  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;

    shellWrapperName = "y";

    keymap = {
      mgr.prepend_keymap = [
        { 
          run  = ''shell "$SHELL" --block'';
          on   = [ "!" ];
          desc = "Open $SHELL here";
        }
      ];
    };
  };
}
