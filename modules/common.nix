# Common configuration shared across all hosts
{ pkgs, nixvim, config, lib, ... }:

let
  isDesktop = config.services.xserver.enable;
  commonPkgs = (import ./base-packages.nix { inherit pkgs nixvim isDesktop; }).common;
in
{
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.elicb = {
    isNormalUser = true;
    description = "Eli Barbieri";
    shell = pkgs.nushell;
    extraGroups = [ "networkmanager" "wheel" ];  # Base groups
    hashedPassword = "$y$j9T$z8JqBQIdcU1et3H0j4QSY/$G6PrAO02DW7mgTs/mE28f7n8nNS1HWMeeKw/ZmipgP/";
  };

  environment.shells = [ pkgs.nushell ];

  environment.systemPackages = commonPkgs;

  # uv needs basic libs to run downloaded python executables (.venv/bin/python)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Base system libraries
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      glibc
      util-linux  # provides libuuid
      expat
      libxcb  # X11 protocol (needed by OpenCV/cv2)
      glib    # needed by PyQt6
    ];
  };

  environment = {
    # System-level environment variables (used by system services)
    variables = {
      CARGO_HOME = "$HOME/.cargo";
    };

    # Session variables (available to all user shells and applications)
    sessionVariables = {
      EDITOR = "nvim";
    };

    # Note: User PATH is now managed by home-manager (see home/default.nix)
    # and nushell (see dotfiles/nushell/env.nu)
  };

  # Keep the store from growing unbounded: collect old generations weekly and
  # hardlink-deduplicate the store after each build.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # Drop the generated HTML/NixOS manual from the system closure (man pages and
  # other docs are unaffected).
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

  # Host-specific services
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false; # Don't block boot; starts via socket activation or when a dependent service needs it
  };

  # libvirt for VMs and crc (local OpenShift cluster)
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  programs.virt-manager.enable = true;

  # Common services all hosts need
  services = {
    openssh.enable = true;
    printing.enable = true;
    power-profiles-daemon.enable = true;
  };

  # Enable wireshark for packet capture capabilities (needed for arp-scan, etc)
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

  networking.networkmanager.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 18;
    consoleMode = "auto";
  };

  # Shorten the systemd-boot menu wait (was defaulting to 5s). Hold a key at
  # boot to interrupt and pick an older generation.
  boot.loader.timeout = 1;

  system.nixos.label = "";  # Disables the majority of the machine/os ID in the systemd boot entries

  boot.loader.efi.canTouchEfiVariables = true;

  # Periodic SSD TRIM (weekly) — keeps NVMe write performance from degrading.
  services.fstrim.enable = true;

}
