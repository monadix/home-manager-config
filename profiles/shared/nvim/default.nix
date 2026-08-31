{ 
  pkgs,
  ... 
}:
{
  programs.neovim = 
  let 
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: toLua (builtins.readFile file);
  in {
    enable = true;

    withRuby = false;
    withPython3 = false;
    
    initLua = builtins.readFile ./options.lua;
    extraPackages = with pkgs; [
      xclip
    ];

    plugins = with pkgs.vimPlugins; [
      {
        plugin = nord-nvim;
        type = "viml";
        config = "colorscheme nord";
      }
      {
        plugin = orgmode;
        type = "lua";

        config = ''
           require("orgmode").setup({
             org_agenda_files = { "~/org/*.org" },
             org_default_notes_file = "~/org/inbox.org",

             org_todo_keywords = {
               "TODO",
               "NEXT",
               "|",
               "DONE",
             },
           })
        '';
      }
    ];

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
