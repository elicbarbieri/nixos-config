{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/nixos-config/dotfiles";
in
{
  home.stateVersion = "25.05";
  
  home.file = {
    ".config/atuin".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/atuin";
    ".config/btop".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/btop";
    ".config/git".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/git";
    ".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr";
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/kitty";
    ".config/lazygit".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/lazygit";
    ".config/neofetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/neofetch";
    ".config/nushell".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nushell";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nvim";
    ".config/rofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/rofi";
    ".config/ruff".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/ruff";
    ".config/gamemode.ini".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/gamemode/gamemode.ini";
  };


  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "orchis-theme";
      package = pkgs.orchis-theme;
    };
  };
}
