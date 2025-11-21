{ config, pkgs, lib, ... }:

{
  imports = [
    ./base.nix
  ];

  # Desktop-specific configuration (GUI apps, theming, etc.)
  home.file = {
    ".config/btop".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/btop";
    ".config/git".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/git";
    ".config/gtk-3.0".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/gtk/gtk-3.0";
    ".config/gtk-4.0".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/gtk/gtk-4.0";
    ".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/hypr";
    ".config/Kvantum".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/Kvantum";
    ".config/lazygit".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/lazygit";
    ".config/qt6ct".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/qt6ct";
    ".config/rofi".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/rofi";
    ".config/ruff".source = config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/ruff";
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
