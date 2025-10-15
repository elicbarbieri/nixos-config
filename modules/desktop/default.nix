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
    
    # Disable GTK management - we handle it ourselves with matugen
    enableGtk = false;
    
    # Keybinds managed manually in dotfiles (see ax-shell-module/README.md)
    keybinds.mode = "disabled";
    
    # Matugen templates for rofi, GTK, and Kvantum theming
    matugen.config = ''
      [templates.rofi]
      input_path = "~/.config/rofi/colors.rasi.template"
      output_path = "~/.config/rofi/colors.rasi"
      
      [templates.gtk3-css]
      input_path = "~/nixos-config/dotfiles/gtk/gtk-3.0/gtk.css.template"
      output_path = "~/.config/gtk-3.0/gtk.css"
      
      [templates.gtk4-css]
      input_path = "~/nixos-config/dotfiles/gtk/gtk-4.0/gtk.css.template"
      output_path = "~/.config/gtk-4.0/gtk.css"
      
      [templates.kvantum-theme]
      input_path = "~/.config/Kvantum/MatugenDynamic/MatugenDynamic.kvconfig.template"
      output_path = "~/.config/Kvantum/MatugenDynamic/MatugenDynamic.kvconfig"
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

  # Theming packages (configuration via dotfiles)
  environment.systemPackages = with pkgs; [
    # Qt theming - config handled by qt6ct dotfiles
    qt6ct
    libsForQt5.qtstyleplugin-kvantum  # Qt5 Kvantum support
    kdePackages.qtstyleplugin-kvantum # Qt6 Kvantum support
    catppuccin-kvantum                # Catppuccin Kvantum theme
    
    # GTK theming - config handled by gtk dotfiles
    adw-gtk3                          # Modern GTK3 theme (libadwaita port)
    adwaita-icon-theme                # Adwaita icons (required for libadwaita symbolic icons)
  ];

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
