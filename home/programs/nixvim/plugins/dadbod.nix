{ ... }: {
  # SQL file types that dadbod supports
  # Disable vim's default SQL completion to avoid conflicts
  globals = {
    # Disable nvim default sql_completion plugin to be compatible with nvim-cmp
    # while still showing some keywords from the syntax autocomplete sources
    omni_sql_default_compl_type = "syntax";
    loaded_sql_completion = 1;

    # DBUI Configuration
    db_ui_save_location = "~/.local/share/nvim/dadbod_ui";
    db_ui_tmp_query_location = "~/.local/share/nvim/dadbod_ui/tmp";
    db_ui_show_database_icon = true;
    db_ui_use_nerd_fonts = true;
    db_ui_use_nvim_notify = true;
    db_ui_auto_execute_table_helpers = true;
    db_ui_execute_on_save = false;
  };

  plugins = {
    # Core database plugin
    vim-dadbod = {
      enable = true;
    };

    # Database UI
    vim-dadbod-ui = {
      enable = true;
    };

    # SQL completion integration
    vim-dadbod-completion = {
      enable = true;
    };
  };

  # Keymaps (following LazyVim defaults)
  keymaps = [
    {
      mode = "n";
      key = "<leader>D";
      action = "<cmd>DBUIToggle<cr>";
      options.desc = "Toggle DBUI";
    }
  ];

  # Auto-configure vim-dadbod-completion source for SQL file types
  extraConfigLua = ''
    -- Configure vim-dadbod-completion for SQL files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "sql" },
      callback = function()
        local cmp = require("cmp")
        
        -- Don't add completion to vim-dadbod-ui special buffers
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname:match("dbui") or bufname:match("dbout") then
          return
        end
        
        -- Setup buffer-specific completion sources for SQL files
        cmp.setup.buffer({
          sources = {
            { name = "vim-dadbod-completion", priority = 1000 },  -- Highest priority for DB completion
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "buffer" },
            { name = "path" },
          },
        })
      end,
    })
    
    -- Disable auto-completion in vim-dadbod-ui buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "dbui", "dbout" },
      callback = function()
        local cmp = require("cmp")
        -- Only trigger completion manually with <C-Space> in UI buffers
        cmp.setup.buffer({
          completion = {
            autocomplete = false
          }
        })
      end,
    })
  '';
}
