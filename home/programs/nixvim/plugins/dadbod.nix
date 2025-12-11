{ ... }: {
  # SQL file types that dadbod supports
  # Disable vim's default SQL completion to avoid conflicts
  globals = {
    # Disable nvim default sql_completion plugin to be compatible with nvim-cmp
    # while still showing some keywords from the syntax autocomplete sources
    omni_sql_default_compl_type = "syntax";
    loaded_sql_completion = 1;
    
    # DBUI Configuration
    db_ui_save_location = "$HOME/.local/share/nvim/dadbod_ui";
    db_ui_tmp_query_location = "$HOME/.local/share/nvim/dadbod_ui/tmp";
    db_ui_show_database_icon = true;
    db_ui_use_nerd_fonts = true;
    db_ui_use_nvim_notify = true;
    db_ui_auto_execute_table_helpers = true;
    
    # NOTE: The default behavior of auto-execution of queries on save is disabled
    # this is useful when you have a big query that you don't want to run every time
    # you save the file running those queries can crash neovim to run use the
    # default keymap: <leader>S
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
    -- SQL file types that dadbod supports (PostgreSQL and SQLite)
    local sql_ft = { "sql" }
    
    -- Add vim-dadbod-completion to nvim-cmp sources for SQL file types
    vim.api.nvim_create_autocmd("FileType", {
      pattern = sql_ft,
      callback = function()
        local cmp = require("cmp")
        
        -- Get current buffer sources
        local sources = cmp.get_config().sources
        
        -- Create a new sources table with vim-dadbod-completion added
        local new_sources = {}
        for _, source in ipairs(sources) do
          table.insert(new_sources, { name = source.name })
        end
        
        -- Add vim-dadbod-completion source
        table.insert(new_sources, { name = "vim-dadbod-completion" })
        
        -- Update sources for the current buffer
        cmp.setup.buffer({ sources = new_sources })
      end,
    })
  '';
}
