{ config, pkgs, lib, ... }:

{
  imports = [
    ./base.nix
  ];
  
  # Desktop-specific configuration (GUI apps, theming, etc.)
  home.file = {
    ".config/btop".source = ../dotfiles/btop;
    ".config/git".source = ../dotfiles/git;
    ".config/gtk-3.0".source = ../dotfiles/gtk/gtk-3.0;
    ".config/gtk-4.0".source = ../dotfiles/gtk/gtk-4.0;
    ".config/hypr".source = ../dotfiles/hypr;
    ".config/kitty".source = ../dotfiles/kitty;
    ".config/Kvantum".source = ../dotfiles/Kvantum;
    ".config/lazygit".source = ../dotfiles/lazygit;
    ".config/qt6ct".source = ../dotfiles/qt6ct;
    ".config/rofi".source = ../dotfiles/rofi;
    ".config/ruff".source = ../dotfiles/ruff;
  };


  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
