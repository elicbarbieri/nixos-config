# Common configuration shared across all hosts
{ pkgs, ... }:

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
    ripgrep
    tree
    
    # Core GUI Apps
    brave
    nautilus
    spotify
    pavucontrol

    # TUI Apps
    opencode
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
    # Adding cargo home so cargo install __ will work
    variables = {
      CARGO_HOME = "$HOME/.cargo";
    };
    # .cargo/bin is for cargo install -- .local/bin is for uv tool install
    extraInit = ''
      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # Common services all hosts need
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Performance CPU governor for development
  powerManagement.cpuFreqGovernor = "performance";

  # GPG agent configuration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
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
