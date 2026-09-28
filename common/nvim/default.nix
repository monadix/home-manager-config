{
  pkgs,
  telescope-orgmode,
  ...
}:

let
  telescopeOrgmode = pkgs.vimUtils.buildVimPlugin {
    pname = "telescope-orgmode.nvim";
    version = "unstable";
    src = telescope-orgmode;
    doCheck = false;
  };
in
{
  programs.neovim = {
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
            -- Both semantic tasks and temporal plan entries appear
            -- in the agenda.
            org_agenda_files = {
              "~/org/tasks.org",
              "~/org/plans.org",
            },

            org_default_notes_file = "~/org/inbox.org",

            -- NEXT is derived from presence in plans.org rather than
            -- stored as a separate task state.
            org_todo_keywords = {
              "TODO",
              "|",
              "DONE",
            },

            -- Links selected by telescope-orgmode use stable IDs.
            org_id_link_to_org_use_id = true,
            org_id_method = "uuid",

            -- Use the Nix-store path rather than depending on PATH.
            org_id_uuid_program = "${pkgs.util-linux}/bin/uuidgen",
          })
        '';
      }

      plenary-nvim
      telescope-nvim

      {
        plugin = telescopeOrgmode;
        type = "lua";
        config = ''
          local telescope = require("telescope")
          telescope.load_extension("orgmode")

          local orgpicker = telescope.extensions.orgmode

          vim.keymap.set(
            "n",
            "<leader>oil",
            orgpicker.insert_link,
            { desc = "Insert link to Org heading" }
          )

          vim.keymap.set(
            "n",
            "<leader>of",
            orgpicker.search_headings,
            { desc = "Find Org heading" }
          )
        '';
      }
    ];

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}

