{ lib, ... }:

let
  palette = import ./palette.nix;
in
{
  programs.ghostty = {
    enable = true;

    themes.custom = {
      inherit (palette) foreground background;
      cursor-color = palette.cursor;
      cursor-text = palette.cursorText;
      selection-foreground = palette.selectionForeground;
      selection-background = palette.selectionBackground;
      palette = lib.imap0 (i: c: "${toString i}=${c}") palette.ansi;
    };

    settings = {
      theme = "custom";
      # wrapped nu (login shell = bare pkgs.nushell, no config)
      command = "nu";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      alpha-blending = "linear";
      # Super+Enter = new window in the running instance → would copy last window's cwd
      window-inherit-working-directory = false;
      working-directory = "home";
      window-padding-x = 10;
      window-padding-y = 10;
      window-decoration = "none";
      confirm-close-surface = false;
    };
  };
}
