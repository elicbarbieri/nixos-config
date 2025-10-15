# Common configuration shared across all hosts
{ pkgs, ... }:

let
  pinentry-rofi-themed = pkgs.writeShellScriptBin "pinentry-rofi-themed" ''
    exec ${pkgs.pinentry-rofi}/bin/pinentry-rofi -- -theme ~/.config/rofi/pinentry.rasi "$@"
  '';
in
{
  # Shared settings across ALL hosts
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Common user configuration with nushell as default shell
  users.users.elicb = {
    isNormalUser = true;
    description = "Eli Barbieri";
    shell = pkgs.nushell;  # Global default - can be overridden per host
    extraGroups = [ "networkmanager" "wheel" ];  # Base groups
  };

  environment.shells = [ pkgs.nushell ];
  
  # Common system packages
  environment.systemPackages = with pkgs; [
    # Shell & Terminal
    kitty
    nushell
    atuin
    carapace

    # Core HID deps
    keyd

    # Utils
    bat
    brightnessctl
    fd
    fzf
    gnupg
    pinentry-rofi-themed
    ripgrep
    tree
    
    # Core GUI Apps
    brave
    nautilus
    spotify
    pavucontrol

    # TUI Apps
    lazydocker
    lazygit
    btop
    
    # Development
    neovim
    tmux
    git
    uv
    rustc
    cargo
    gcc
    nodejs
    bun
    go

    # Work & Productivity
    super-productivity
    slack
  ];

  # uv needs basic libs to run downloaded python executables (.venv/bin/python)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      libz
      glibc
    ];
  };
 
  environment = {
    # System-level environment variables (used by system services)
    variables = {
      CARGO_HOME = "$HOME/.cargo";
    };
    # Note: User PATH is now managed by home-manager (see home/default.nix)
    # and nushell (see dotfiles/nushell/env.nu)
  };

  # Common services all hosts need
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Performance CPU governor for development
  powerManagement.cpuFreqGovernor = "performance";

  # GPG agent configuration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pinentry-rofi-themed;
  };

  # Common services all hosts need
  services = {
    openssh.enable = true;
    printing.enable = true;
  };

  system.stateVersion = "25.05";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
}
