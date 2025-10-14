# Desktop environment module - Hyprland + Ax-Shell integration
{ pkgs, ... }:

{
  # Ax-shell configuration - only the actual non-default settings needed
  programs.ax-shell = {
    enable = true;
    user = "elicb";
    wallpapersDir = "/home/elicb/nixos-config/assets/wallpapers";
    defaultWallpaper = ./../../assets/wallpapers/dark-circuit.jpeg;
    dockAlwaysOccluded = true;
    barWorkspaceShowNumber = true;
    
    # Keybinds managed manually in dotfiles (see ax-shell-module/README.md)
    keybinds.mode = "disabled";
    
    # Matugen template for rofi colors
    matugen.config = ''
      [templates.rofi]
      input_path = "~/.config/rofi/colors.rasi.template"
      output_path = "~/.config/rofi/colors.rasi"
    '';
  };

  # Enable X server for session management  
  services.xserver.enable = true;
  
  # Enable Hyprland
  programs.hyprland.enable = true;

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
  };

  # Essential desktop services
  services = {
    # Display manager - using SDDM for better Wayland compatibility
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      autoLogin = {
        enable = true;
        user = "elicb";
      };

    };
    
    # Audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Hardware services
    upower.enable = true;
    blueman.enable = true;
    
    # System services
    dbus.enable = true;
    udisks2.enable = true;
  };

  # Hardware support
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Security
  security = {
    rtkit.enable = true;
  };

  # Networking
  networking.networkmanager.enable = true;

  # Fonts for Ax-Shell and system
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
    nerd-fonts.symbols-only
  ];
  
  # Set JetBrainsMono as default system font
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "JetBrainsMono Nerd Font" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
