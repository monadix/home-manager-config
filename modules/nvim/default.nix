{ pkgs
,
... }:
{
  programs.neovim = 
  let 
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: toLua (builtins.readFile file);
  in {
    enable = true;
    
    extraLuaConfig = builtins.readFile ./options.lua;
    extraPackages = with pkgs; [
      xclip
    ];

    plugins = with pkgs.vimPlugins; [
      {
        plugin = nord-nvim;
        config = "colorscheme nord";
      }
    ];

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
