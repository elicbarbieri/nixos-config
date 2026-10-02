{ ... }: {
  plugins = {
      # Git signs in the gutter
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            delay = 300;
            virt_text = true;
            virt_text_pos = "eol";
          };
          signs = {
            add = {
              text = "│";
            };
            change = {
              text = "│";
            };
            delete = {
              text = "_";
            };
            topdelete = {
              text = "‾";
            };
            changedelete = {
              text = "~";
            };
            untracked = {
              text = "┆";
            };
          };
        };
      };
      
      # Git diff view
      diffview.enable = true;
    };
    
  # Keymaps for git (LazyVim style)
  keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        # real lazygit in zellij float (own colours, nvim stays open)
        # - --blocking → checktime once pane closes (checkout/discard rewrite files)
        action.__raw = ''
          function()
            if not vim.env.ZELLIJ then
              vim.notify("lazygit float needs zellij", vim.log.levels.WARN)
              return
            end
            vim.system({
              "zellij", "run", "--floating", "--close-on-exit", "--blocking", "--name", "lazygit",
              "--width", "90%", "--height", "90%", "--x", "5%", "--y", "5%",
              "--cwd", vim.fn.getcwd(), "--", "lazygit",
            }, {}, vim.schedule_wrap(function() vim.cmd.checktime() end))
          end
        '';
        options.desc = "Lazygit (zellij float)";
      }
      
      # Git diff
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>DiffviewOpen<cr>";
        options.desc = "Git Diff";
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<cmd>DiffviewClose<cr>";
        options.desc = "Close Diff";
      }
      
      # File history
      {
        mode = "n";
        key = "<leader>gf";
        action = "<cmd>DiffviewFileHistory<cr>";
        options.desc = "Git File History";
      }
      {
        mode = "n";
        key = "<leader>gl";
        action = "<cmd>DiffviewFileHistory<cr>";
        options.desc = "Git Log";
      }
      
      # Hunk navigation
      {
        mode = "n";
        key = "]h";
        action = "<cmd>Gitsigns next_hunk<cr>";
        options.desc = "Next Hunk";
      }
      {
        mode = "n";
        key = "[h";
        action = "<cmd>Gitsigns prev_hunk<cr>";
        options.desc = "Prev Hunk";
      }
      
      # Hunk operations
      {
        mode = "n";
        key = "<leader>ghp";
        action = "<cmd>Gitsigns preview_hunk<cr>";
        options.desc = "Preview Hunk";
      }
      {
        mode = "n";
        key = "<leader>ghr";
        action = "<cmd>Gitsigns reset_hunk<cr>";
        options.desc = "Reset Hunk";
      }
      {
        mode = "n";
        key = "<leader>ghs";
        action = "<cmd>Gitsigns stage_hunk<cr>";
        options.desc = "Stage Hunk";
      }
      {
        mode = "n";
        key = "<leader>ghu";
        action = "<cmd>Gitsigns undo_stage_hunk<cr>";
        options.desc = "Undo Stage Hunk";
      }
      
      # Git blame
      {
        mode = "n";
        key = "<leader>gb";
        action = "<cmd>Gitsigns blame_line<cr>";
        options.desc = "Git Blame Line";
      }
      {
        mode = "n";
        key = "<leader>gB";
        action = "<cmd>Gitsigns blame<cr>";
        options.desc = "Git Blame Buffer";
      }
    ];
}
