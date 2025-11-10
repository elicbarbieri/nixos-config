{ ... }: {
  plugins = {
      # Enhanced f/F/t/T motions
      flash = {
        enable = true;
        settings = {
          modes = {
            search.enabled = true;
          };
        };
      };
      
      # Autopairs
      nvim-autopairs = {
        enable = true;
        settings = {
          check_ts = true;
        };
      };
      
      # Better escape
      better-escape = {
        enable = true;
        settings = {
          timeout = 300;
        };
      };
      
      # Trouble (diagnostics list)
      trouble = {
        enable = true;
        settings = {
          auto_close = true;
        };
      };
      
      # Illuminate (highlight word under cursor)
      illuminate = {
        enable = true;
        settings = {
          under_cursor = false;
          filetypes_denylist = [
            "neo-tree"
            "alpha"
          ];
        };
      };
      
      # Undotree
      undotree = {
        enable = true;
        settings = {
          focusOnToggle = true;
        };
      };
      
      # Toggle terminal
      toggleterm = {
        enable = true;
        settings = {
          direction = "float";
          float_opts = {
            border = "curved";
          };
        };
      };
      
      # Web devicons
      web-devicons.enable = true;
      
      # Nvim-spider (better word motions)
      # nvim-spider = {
      #   enable = true;
      # };
    };
    
  # Keymaps for utils
  keymaps = [
      # Diagnostics/Trouble (LazyVim <leader>x namespace)
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options.desc = "Buffer Diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xl";
        action = "<cmd>Trouble loclist toggle<cr>";
        options.desc = "Location List (Trouble)";
      }
      {
        mode = "n";
        key = "<leader>xq";
        action = "<cmd>Trouble qflist toggle<cr>";
        options.desc = "Quickfix List (Trouble)";
      }
      
      # Quickfix navigation
      {
        mode = "n";
        key = "[q";
        action = "<cmd>cprev<cr>";
        options.desc = "Previous Quickfix";
      }
      {
        mode = "n";
        key = "]q";
        action = "<cmd>cnext<cr>";
        options.desc = "Next Quickfix";
      }
      
      # UI Toggles (LazyVim <leader>u namespace)
      {
        mode = "n";
        key = "<leader>uu";
        action = "<cmd>UndotreeToggle<cr>";
        options.desc = "Undo Tree";
      }
      {
        mode = "n";
        key = "<leader>us";
        action = "<cmd>set spell!<cr>";
        options.desc = "Toggle Spelling";
      }
      {
        mode = "n";
        key = "<leader>uw";
        action = "<cmd>set wrap!<cr>";
        options.desc = "Toggle Wrap";
      }
      {
        mode = "n";
        key = "<leader>ul";
        action = "<cmd>set number!<cr>";
        options.desc = "Toggle Line Numbers";
      }
      {
        mode = "n";
        key = "<leader>uL";
        action = "<cmd>set relativenumber!<cr>";
        options.desc = "Toggle Relative Numbers";
      }
      {
        mode = "n";
        key = "<leader>ud";
        action = "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<cr>";
        options.desc = "Toggle Diagnostics";
      }
      
      # Terminal (LazyVim defaults - using ft for file tree terminal)
      {
        mode = "n";
        key = "<leader>ft";
        action = "<cmd>ToggleTerm<cr>";
        options.desc = "Terminal (Root Dir)";
      }
      {
        mode = "n";
        key = "<leader>fT";
        action = "<cmd>ToggleTerm<cr>";
        options.desc = "Terminal (cwd)";
      }
      {
        mode = ["n" "t"];
        key = "<C-/>";
        action = "<cmd>ToggleTerm<cr>";
        options.desc = "Terminal (Root Dir)";
      }
    ];
}
