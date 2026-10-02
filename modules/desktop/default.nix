# Desktop environment module - Hyprland + Ax-Shell integration
{ pkgs, ... }:

let
  pinentry-rofi-themed = pkgs.writeShellScriptBin "pinentry-rofi-themed" ''
    exec ${pkgs.pinentry-rofi}/bin/pinentry-rofi -- -theme ~/.config/rofi/pinentry.rasi "$@"
  '';

  # launcher default terminal = xterm
  nvim-desktop = pkgs.makeDesktopItem {
    name = "nvim";
    desktopName = "Neovim";
    genericName = "Text Editor";
    comment = "Edit text files";
    exec = "ghostty -e nvim %F";
    icon = "nvim";
    terminal = false;
    categories = [ "Utility" "TextEditor" ];
    mimeTypes = [
      "text/english" "text/plain" "text/x-makefile" "text/x-c++hdr"
      "text/x-c++src" "text/x-chdr" "text/x-csrc" "text/x-java"
      "text/x-moc" "text/x-pascal" "text/x-tcl" "text/x-tex"
      "application/x-shellscript" "text/x-c" "text/x-c++"
    ];
  };
in
{
  imports = [
    ./sddm-theme.nix
  ];
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
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh";
  };

  # Essential desktop services
  services = {
    # Display manager - using SDDM for better Wayland compatibility
    # Auto-login disabled to allow proper GNOME Keyring unlock via PAM
    displayManager = {
      autoLogin = {
        enable = false;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      # RT scheduling module with proper priorities
      extraConfig.pipewire."91-realtime" = {
        "context.modules" = [
          {
            name = "libpipewire-module-rt";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = [ "ifexists" "nofail" ];
          }
        ];
      };
    };

    # Hardware services
    upower.enable = true;
    blueman.enable = true;

    # System services
    dbus.enable = true;
    udisks2.enable = true;

    # general service discovery only (printing uses a literal IP - LAN drops multicast, mDNS unusable)
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish.enable = false;
    };

    # Secrets management - required by GUI apps like atuin-desktop
    gnome.gnome-keyring.enable = true;

    # Logind configuration for lid switch handling
    logind.settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
    };

  };

  # nixpkgs#554650: sandbox drops CAP_DAC_OVERRIDE → stale pid unremovable → every later start EEXIST
  # `+` = ExecStartPre outside sandbox, Restart= = upstream default dropped by the nixpkgs module
  systemd.services.avahi-daemon.serviceConfig = {
    ExecStartPre = "+${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid";
    Restart = "on-failure";
  };

  systemd.sleep.settings.Sleep = {
    SuspendState = "mem";
    HibernateMode = "shutdown";
  };

  # Hardware support
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    keyboard.zsa.enable = true;  # ZSA keyboard support (udev rules)
  };

  # Security
  security = {
    rtkit.enable = true;

    # PAM configuration for auto-unlocking gnome-keyring
    pam.services.sddm.enableGnomeKeyring = true;

    # PAM limits for @audio - gives PipeWire RLIMIT_RTPRIO (preferred over rtkit)
    pam.loginLimits = [
      { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
      { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
      { domain = "@audio"; item = "nice";    type = "-"; value = "-20"; }
    ];
  };


  # XDG portal configuration (required for Flatpak GTK apps)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Flatpak configuration
  services.flatpak = {
    enable = true;
    packages = [
      "com.spotify.Client"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };

  environment.systemPackages = [
    nvim-desktop
  ] ++ (with pkgs; [

    # Core HID deps
    keymapp  # ZSA keyboard configurator and flashing tool
    pinentry-rofi-themed
    brightnessctl

    # Atuin Desktop & Keyring Deps
    libsecret  # Provides secret-tool for keyring management
    seahorse
    atuin-desktop

    # Core GUI Apps (fast-moving: protocol/security churn)
    halloy
    brave
    pavucontrol
    telegram-desktop
    signal-desktop
    mpv

    # Qt theming - config handled by qt6ct dotfiles
    # - plugins load into every Qt app's process → must share the apps' Qt (unstable)
    qt6Packages.qt6ct
    libsForQt5.qtstyleplugin-kvantum  # Qt5 Kvantum support
    kdePackages.qtstyleplugin-kvantum # Qt6 Kvantum support
  ]) ++ (with pkgs.stable; [
    # Heavy GUI apps
    blender
    nautilus
    deluge
    plex-desktop
    ffmpeg-full

    # GUI Dev Tools
    tracy

    # Theme data (no linked libs → channel-agnostic)
    catppuccin-kvantum
    adw-gtk3
    adwaita-icon-theme  # libadwaita symbolic icons
  ]);

  # GPG agent configuration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pinentry-rofi-themed;
  };

  # Fonts for Ax-Shell and system
  fonts.packages = with pkgs.stable; [
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

  systemd.user.services.hypridle = {
    description = "Hyprland idle daemon";
    documentation = [ "https://wiki.hyprland.org/Hypr-Ecosystem/hypridle" ];
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };

  # Kernel tuning for realtime audio
  boot.kernelParams = [
    "preempt=full"  # Full kernel preemption - reduces scheduling latency
    "threadirqs"    # Threaded IRQ handlers - preemptible by RT threads
  ];

  # Fix Intel SOF audio driver bugs during gaming (disable audio power saving)
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
  '';
}
