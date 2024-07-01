{ ... }:
{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set-option -g prefix C-q
      set -g mouse on
    '';
  };
}
