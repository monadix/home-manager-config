{ ... }:
{
  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;

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
