{ ... }: {
  plugins.telescope = {
      enable = true;
      
      extensions = {
        fzf-native.enable = true;
        ui-select.enable = true;
      };
      
      settings = {
        defaults = {
          file_ignore_patterns = [
            "^.git/"
            "node_modules/"
            ".venv/"
            "__pycache__/"
            "*.pyc"
          ];
          hidden = true;
          layout_config = {
            horizontal = {
              prompt_position = "top";
            };
          };
          sorting_strategy = "ascending";
        };
      };
      
      keymaps = {
        # Quick access (LazyVim style)
        "<leader><space>" = {
          action = "find_files";
          options.desc = "Find Files (Root Dir)";
        };
        "<leader>/" = {
          action = "live_grep";
          options.desc = "Grep (Root Dir)";
        };
        "<leader>," = {
          action = "buffers";
          options.desc = "Switch Buffer";
        };
        
        # Search namespace (LazyVim <leader>s)
        "<leader>sg" = {
          action = "live_grep";
          options.desc = "Grep (Root Dir)";
        };
        "<leader>sG" = {
          action = "live_grep";
          options.desc = "Grep (cwd)";
        };
        "<leader>sw" = {
          action = "grep_string";
          options.desc = "Word (Root Dir)";
        };
        "<leader>sW" = {
          action = "grep_string";
          options.desc = "Word (cwd)";
        };
        "<leader>sb" = {
          action = "current_buffer_fuzzy_find";
          options.desc = "Buffer";
        };
        "<leader>sc" = {
          action = "command_history";
          options.desc = "Command History";
        };
        "<leader>sC" = {
          action = "commands";
          options.desc = "Commands";
        };
        "<leader>sd" = {
          action = "diagnostics";
          options.desc = "Diagnostics";
        };
        "<leader>sh" = {
          action = "help_tags";
          options.desc = "Help Pages";
        };
        "<leader>sk" = {
          action = "keymaps";
          options.desc = "Keymaps";
        };
        "<leader>sm" = {
          action = "marks";
          options.desc = "Marks";
        };
        "<leader>sr" = {
          action = "oldfiles";
          options.desc = "Recent";
        };
        "<leader>sR" = {
          action = "resume";
          options.desc = "Resume";
        };
        
        # File namespace (keep for compatibility)
        "<leader>ff" = {
          action = "find_files";
          options.desc = "Find Files (Root Dir)";
        };
        "<leader>fF" = {
          action = "find_files";
          options.desc = "Find Files (cwd)";
        };
        "<leader>fb" = {
          action = "buffers";
          options.desc = "Buffers";
        };
        "<leader>fr" = {
          action = "oldfiles";
          options.desc = "Recent";
        };
        "<leader>fR" = {
          action = "oldfiles";
          options.desc = "Recent (cwd)";
        };
        
        # Git files
        "<leader>fg" = {
          action = "git_files";
          options.desc = "Find Files (git-files)";
        };
        
        # LSP Symbols (LazyVim <leader>ss and <leader>sS)
        "<leader>ss" = {
          action = "lsp_document_symbols";
          options.desc = "LSP Symbols";
        };
        "<leader>sS" = {
          action = "lsp_workspace_symbols";
          options.desc = "LSP Workspace Symbols";
        };
      };
    };
}
