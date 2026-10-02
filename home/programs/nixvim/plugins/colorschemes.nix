{ ... }:

let
  palette = import ../../palette.nix;
  ansi = builtins.elemAt palette.ansi;
in
{
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "mocha";
      # Mocha accents + blue-grey ramp; base lifted off terminal black (nvim vs shell at a glance)
      color_overrides.mocha = {
        base = "#101216";
        mantle = "#0b0c0f";
        crust = "#060709";
        surface0 = "#1b1d23";
        surface1 = "#2a2c33";
        surface2 = ansi 8;
        overlay0 = "#555861";
        overlay1 = "#6f727c";
        overlay2 = "#8b8e98";
        subtext0 = "#a6a9b3";
        subtext1 = palette.cursorText;
        text = palette.foreground;
      };
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
