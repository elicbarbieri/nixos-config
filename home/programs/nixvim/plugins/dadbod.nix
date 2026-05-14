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

}
