{ ... }: {
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "mocha";
      transparent_background = false;
      term_colors = true;
      integrations = {
        cmp = true;
        gitsigns = true;
        nvimtree = true;
        treesitter = true;
        telescope = {
          enabled = true;
        };
        mini = {
          enabled = true;
        };
        native_lsp = {
          enabled = true;
          underlines = {
            errors = ["underline"];
            hints = ["underline"];
            warnings = ["underline"];
            information = ["underline"];
          };
        };
      };
    };
  };
}
