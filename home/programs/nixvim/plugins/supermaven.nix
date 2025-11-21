{ ... }: {
  plugins.supermaven = {
    enable = true;
    settings = {
      keymaps = {
        accept_suggestion = "<C-y>";
        clear_suggestion = "<C-e>";
        accept_word = "<C-n>";
      };
      color = {
        suggestion_color = "#808080";
        cterm = 244;
      };
      log_level = "info";
      disable_inline_completion = false;
      disable_keymaps = false;
    };
  };
}
