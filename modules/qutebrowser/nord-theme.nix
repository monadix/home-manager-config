let 
  nord = {
    # polar night
    nord0 = "#2e3440";
    nord1 = "#3b4252";
    nord2 = "#434c5e";
    nord3 = "#4c566a";
    # snow storm
    nord4 = "#d8dee9";
    nord5 = "#e5e9f0";
    nord6 = "#eceff4";
    # Frost
    nord7 = "#8fbcbb";
    nord8 = "#88c0d0";
    nord9 = "#81a1c1";
    nord10 = "#5e81ac";
    # Aurora
    nord11 = "#bf616a";
    nord12 = "#d08770";
    nord13 = "#ebcb8b";
    nord14 = "#a3be8c";
    nord15 = "#b48ead";
  };
in 
{
  colors = {
    completion = {
      category = {
        bg = nord.nord0;
        border = {
          bottom = nord.nord0;
          top = nord.nord0;
        };
        fg = nord.nord5;
      };
      even = {
        bg = nord.nord1;
      };
      odd = {
        bg = nord.nord1;
      };
      fg = nord.nord4;
      item = {
        selected = {
          bg = nord.nord3;
          border = {
            bottom = nord.nord3;
            top = nord.nord3;
          };
          fg = nord.nord6;
        };
      };
      match = {
        fg = nord.nord13;
      };
      scrollbar = {
        bg = nord.nord1;
        fg = nord.nord5;
      };
    };
    downloads = {
      bar = {
        bg = nord.nord0;
      };
      error = {
        bg = nord.nord11;
        fg = nord.nord5;
      };
      stop = {
        bg = nord.nord15;
      };
      system = {
        bg = "none";
      };
    };
    hints = {
      bg = nord.nord13;
      fg = nord.nord0;
      match = {
        fg = nord.nord10;
      };
    };
    keyhint = {
      bg = nord.nord1;
      fg = nord.nord5;
      suffix = {
        fg = nord.nord13;
      };
    };
    messages = {
      error = {
        bg = nord.nord11;
        border = nord.nord11;
        fg = nord.nord5;
      };
      info = {
        bg = nord.nord8;
        border = nord.nord8;
        fg = nord.nord5;
      };
      warning = {
        bg = nord.nord12;
        border = nord.nord12;
        fg = nord.nord5;
      };
    };
    prompts = {
      bg = nord.nord2;
      border = "1px solid ${nord.nord0}";
      fg = nord.nord5;
      selected = {
        bg = nord.nord3;
      };
    };
    statusbar = {
      caret = {
        bg = nord.nord15;
        fg = nord.nord5;
        selection = {
          bg = nord.nord15;
          fg = nord.nord5;
        };
      };
      command = {
        bg = nord.nord2;
        fg = nord.nord5;
        private = {
          bg = nord.nord2;
          fg = nord.nord5;
        };
      };
      insert = {
        bg = nord.nord14;
        fg = nord.nord1;
      };
      normal = {
        bg = nord.nord0;
        fg = nord.nord5;
      };
      passthrough = {
        bg = nord.nord10;
        fg = nord.nord5;
      };
      private = {
        bg = nord.nord3;
        fg = nord.nord5;
      };
      progress = {
        bg = nord.nord5;
      };
      url = {
        error = {
          fg = nord.nord11;
        };
        fg = nord.nord5;
        hover = {
          fg = nord.nord8;
        };
        success = {
          http = {
            fg = nord.nord5;
          };
          https = {
            fg = nord.nord14;
          };
        };
        warn = {
          fg = nord.nord12;
        };
      };
    };
    tabs = {
      bar = {
        bg = nord.nord3;
      };
      even = {
        bg = nord.nord3;
        fg = nord.nord5;
      };
      indicator = {
        error = nord.nord11;
        system = "none";
      };
      odd = {
        bg = nord.nord3;
        fg = nord.nord5;
      };
      selected = {
        even = {
          bg = nord.nord0;
          fg = nord.nord5;
        };
        odd = {
          bg = nord.nord0;
          fg = nord.nord5;
        };
      };
    };
  };
}
