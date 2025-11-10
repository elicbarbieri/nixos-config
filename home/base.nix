{ config, pkgs, lib, nixvim, ... }:

{
  imports = [
    nixvim.homeModules.nixvim
    ./programs/nushell.nix
  ];
  
  # For home-manager, wrap nixvim config in programs.nixvim
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
  } // (import ./programs/nixvim { inherit pkgs; });
  
  home.stateVersion = "25.05";
  
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
  ];
  
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.carapace = {
    enable = true;
  };

  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = true;
      sync_frequency = "10m";
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "compact";
      inline_height = 20;
      show_preview = true;
      max_preview_height = 4;
      show_help = true;
      exit_mode = "return-original";
      keymap_mode = "emacs";
      history_filter = [
        "^secret-tool"
        "^adb shell"
        "^ssh"
        "^rsync"
        "^scp"
        "^sudo"
        "^doas"
        "^su"
        "^cd"
        "^ls"
        "^ll"
        "^la"
        "^pwd"
        "^clear"
        "^exit"
        "^history"
        "^which"
        "^whereis"
        "^whatis"
        "^man"
        "^help"
        "^info"
        "^apropos"
        "^type"
        "^alias"
        "^unalias"
        "^echo"
        "^printf"
        "^cat"
        "^less"
        "^more"
        "^head"
        "^tail"
        "^grep"
        "^egrep"
        "^fgrep"
        "^rg"
        "^ag"
        "^ack"
        "^find"
        "^locate"
        "^updatedb"
        "^date"
        "^cal"
        "^uptime"
        "^w"
        "^who"
        "^whoami"
        "^id"
        "^groups"
        "^finger"
        "^last"
        "^lastlog"
        "^ps"
        "^top"
        "^htop"
        "^btop"
        "^pgrep"
        "^pkill"
        "^killall"
        "^jobs"
        "^bg"
        "^fg"
        "^nohup"
        "^screen"
        "^tmux"
        "^apt"
        "^apt-get"
      ];
      workspaces = true;
      common_prefix = [ "sudo" ];
      common_subcommands = [
        "cargo"
        "go"
        "git"
        "npm"
        "yarn"
        "pnpm"
        "kubectl"
        "docker"
        "podman"
        "systemctl"
        "journalctl"
        "make"
        "cmake"
        "mvn"
        "gradle"
      ];
    };
  };
  

  
}
