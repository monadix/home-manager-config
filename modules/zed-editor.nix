{ 
  pkgs,
  ... 
}:
{
  programs.zed-editor = {
    enable = true;
    installRemoteServer = true;

    extensions = [
      "nix"
      "nord"
    ];

    extraPackages = with pkgs; [
      rust-analyzer
      nixd
    ];

    userSettings = {
      ui_font_size = 16;
      buffer_font_size = 16;

      vim_mode = true;
      relative_line_numbers = true;

      theme = "Nord";
    };
  };
}
