{ ... }: {
  plugins = {
    # Status line
    lualine = {
      enable = true;
      settings = {
        options = {
          theme = "auto";
          globalstatus = true;
          disabled_filetypes = {
            statusline = ["dashboard" "alpha" "starter"];
          };
        };
        sections = {
          lualine_a = ["mode"];
          lualine_b = ["branch" "diff" "diagnostics"];
          lualine_c = ["filename"];
          lualine_x = ["encoding" "fileformat" "filetype"];
          lualine_y = ["progress"];
          lualine_z = ["location"];
        };
      };
    };
    
    # Buffer line
    bufferline = {
      enable = true;
      settings = {
        options = {
          diagnostics = "nvim_lsp";
          always_show_bufferline = false;
          offsets = [
            {
              filetype = "neo-tree";
              text = "File Explorer";
              highlight = "Directory";
              text_align = "left";
            }
          ];
        };
      };
    };
    
    # Which-key
    which-key = {
      enable = true;
      settings = {
        preset = "helix";
        delay = 300;
        icons = {
          mappings = true;
        };
        spec = [
          {
            __unkeyed-1 = "<leader><space>";
            desc = "Find Files";
          }
          {
            __unkeyed-1 = "<leader>/";
            desc = "Grep";
          }
          {
            __unkeyed-1 = "<leader>,";
            desc = "Switch Buffer";
          }
          {
            __unkeyed-1 = "<leader>b";
            group = "Buffer";
          }
          {
            __unkeyed-1 = "<leader>c";
            group = "Code";
          }
          {
            __unkeyed-1 = "<leader>f";
            group = "File";
          }
          {
            __unkeyed-1 = "<leader>g";
            group = "Git";
          }
          {
            __unkeyed-1 = "<leader>q";
            group = "Quit/Session";
          }
          {
            __unkeyed-1 = "<leader>s";
            group = "Search";
          }
          {
            __unkeyed-1 = "<leader>u";
            group = "UI";
          }
          {
            __unkeyed-1 = "<leader>w";
            group = "Window";
          }
          {
            __unkeyed-1 = "<leader>x";
            group = "Diagnostics";
          }
          {
            __unkeyed-1 = "<leader><tab>";
            group = "Tabs";
          }
        ];
      };
    };
    
    # File tree
    neo-tree = {
      enable = true;
      settings = {
        close_if_last_window = true;
        window = {
          width = 30;
          auto_expand_width = false;
        };
      };
    };
    
    # Indent guides
    indent-blankline = {
      enable = true;
      settings = {
        scope.enabled = true;
        exclude = {
          filetypes = [
            "help"
            "dashboard"
            "neo-tree"
            "Trouble"
            "trouble"
            "lazy"
            "mason"
            "notify"
            "toggleterm"
          ];
        };
      };
    };
    
    # TODO comments
    todo-comments = {
      enable = true;
      settings = {
        signs = true;
      };
    };
    
    # Mini plugins
    mini = {
      enable = true;
      modules = {
        surround = {};
        pairs = {};
        comment = {};
        ai = {};
      };
    };
    
    # Notify
    notify = {
      enable = true;
      settings = {
        background_colour = "#000000";
        timeout = 3000;
      };
    };
    
    # Dashboard
    alpha = {
      enable = true;
      settings = {
        layout = [
          {
            type = "padding";
            val = 2;
          }
          {
            opts = {
              hl = "Type";
              position = "center";
            };
            type = "text";
            val = [
              "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
              "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
              "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
              "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
              "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
              "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
            ];
          }
          {
            type = "padding";
            val = 1;
          }
          {
            opts = {
              hl = "Comment";
              position = "center";
            };
            type = "text";
            val = [
              "╭─────────────────────── Quick Start ───────────────────────╮"
              "│                                                            │"
              "│  Search                                                    │"
              "│    <l> <space>  Find files       <l> s g  Grep text        │"
              "│    <l> /        Quick grep       <l> s b  Buffers          │"
              "│                                                            │"
              "│  Code                                                      │"
              "│    <l> c a      Code action      <l> c r  Rename           │"
              "│    <l> c f      Format           g d      Go to def        │"
              "│                                                            │"
              "│  Git                                                       │"
              "│    <l> g g      Lazygit          <l> g b  Blame line       │"
              "│    <l> g s      Status           ] h      Next hunk        │"
              "│                                                            │"
              "│  Windows                                                   │"
              "│    <l> w v      Split vertical   <l> w s  Split horiz      │"
              "│    <l> e        File explorer    <l> q q  Quit             │"
              "│                                                            │"
              "╰────────────────────────────────────────────────────────────╯"
            ];
          }
          {
            type = "padding";
            val = 1;
          }
          {
            opts = {
              hl = "Comment";
              position = "center";
            };
            type = "text";
            val = {
              __raw = ''
                function()
                  local version = vim.version()
                  local nvim_version = "v" .. version.major .. "." .. version.minor .. "." .. version.patch
                  
                  -- Count loaded plugins
                  local plugin_count = 0
                  for _ in pairs(package.loaded) do
                    plugin_count = plugin_count + 1
                  end
                  
                  local date = os.date(" %Y-%m-%d")
                  local time = os.date(" %H:%M:%S")
                  
                  -- Try to get git branch
                  local branch = ""
                  local handle = io.popen("git branch --show-current 2>/dev/null")
                  if handle then
                    local result = handle:read("*a")
                    handle:close()
                    if result and result ~= "" then
                      branch = " " .. result:gsub("%s+", "")
                    end
                  end
                  
                  local plugins_text = "⚡ " .. plugin_count .. " modules loaded"
                  local datetime_text = date .. "  " .. time
                  
                  if branch ~= "" then
                    return {
                      plugins_text .. "  " .. datetime_text .. "  " .. branch,
                      nvim_version
                    }
                  else
                    return {
                      plugins_text .. "  " .. datetime_text,
                      nvim_version
                    }
                  end
                end
              '';
            };
          }
        ];
      };
    };
  };
  
  # Keymaps for UI plugins
  keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "Explorer (Root Dir)";
    }
    {
      mode = "n";
      key = "<leader>E";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "Explorer (cwd)";
    }
    {
      mode = "n";
      key = "<leader>fe";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "Explorer (Root Dir)";
    }
    {
      mode = "n";
      key = "<leader>fE";
      action = "<cmd>Neotree toggle<cr>";
      options.desc = "Explorer (cwd)";
    }
  ];
}
