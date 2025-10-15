{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/nixos-config/dotfiles";
in
{
  imports = [
    ./shell.nix
  ];

  home.stateVersion = "25.05";
  
  # Session PATH for bash/zsh/POSIX shells
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
  ];
  
  # Session environment variables for bash/zsh/POSIX shells
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
    MANPAGER = "bat";
  };
  
  home.file = {
    ".config/btop".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/btop";
    ".config/git".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/git";
    ".config/gtk-3.0".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/gtk/gtk-3.0";
    ".config/gtk-4.0".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/gtk/gtk-4.0";
    ".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr";
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/kitty";
    ".config/lazygit".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/lazygit";
    ".config/nushell".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nushell";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nvim";
    ".config/qt6ct".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/qt6ct";
    ".config/rofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/rofi";
    ".config/ruff".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/ruff";
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
