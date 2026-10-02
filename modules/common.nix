{ pkgs, nixvim, config, lib, ... }:

let
  isDesktop = config.services.xserver.enable;
  commonPkgs = (import ./base-packages.nix { inherit pkgs nixvim isDesktop; }).common;
in
{
  imports = [
    ./networking.nix
  ];

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.elicb = {
    isNormalUser = true;
    description = "Eli Barbieri";
    shell = pkgs.nushell;
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$y$j9T$z8JqBQIdcU1et3H0j4QSY/$G6PrAO02DW7mgTs/mE28f7n8nNS1HWMeeKw/ZmipgP/";
  };

  environment.shells = [ pkgs.nushell ];

  environment.systemPackages = commonPkgs;

  programs.nh = {
    enable = true;
    flake = "/home/elicb/nixos-config";
  };

  # prebuilt weekly nix-index db (nix-index-database flake) → `, <cmd>` runs anything in nixpkgs
  programs.nix-index-database.comma.enable = true;

  # uv-downloaded python executables (.venv/bin/python) link these at runtime
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      glibc
      util-linux  # libuuid
      expat
      libxcb      # cv2
      glib        # PyQt6
    ];
  };

  environment = {
    variables = {
      CARGO_HOME = "$HOME/.cargo";
    };

    sessionVariables = {
      EDITOR = "nvim";
    };

    # user PATH → home/default.nix + dotfiles/nushell/env.nu
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # drops generated HTML/NixOS manual from the closure; man pages unaffected
  documentation.nixos.enable = false;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;  # socket-activated, off the boot critical path
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  programs.virt-manager.enable = true;

  services = {
    openssh.enable = true;
    printing = {
      enable = true;
      drivers = lib.optionals isDesktop [ pkgs.canon-cups-ufr2 ];
      # 90pg @1200dpi = ~2.5min, so 30min = dead backend (default 10800 hid one for 3h)
      extraConf = "MaxJobTime 1800";
    };
    power-profiles-daemon.enable = true;
  };

  # grants dumpcap caps to the wireshark group (arp-scan et al)
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;

  security.sudo.extraRules = [{
    users = [ "elicb" ];
    commands = [
      {
        command = "/run/current-system/sw/bin/btop";
        options = [ "NOPASSWD" ];
      }
    ];
  }];

  system.stateVersion = "25.05";


  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 18;
    consoleMode = "auto";
  };

  boot.loader.timeout = 5;

  system.nixos.label = "";  # strips machine/os ID from systemd-boot entries

  boot.loader.efi.canTouchEfiVariables = true;

  services.fstrim.enable = true;

}
