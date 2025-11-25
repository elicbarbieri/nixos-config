# Common configuration shared across all hosts
{ pkgs, nixvim, config, lib, ... }:

let
  commonPkgs = (import ./base-packages.nix { inherit pkgs nixvim; }).common;
in
{
  nixpkgs.config.cudaSupport = true;
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

  environment.systemPackages = commonPkgs ++ (with pkgs; [
    # CUDA development tools (needed for vLLM/FlashInfer JIT compilation)
    ninja
    cmake
    cudaPackages.cudatoolkit  # Provides nvcc and other CUDA tools
  ]);

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

      # NVIDIA Driver libraries (required for CUDA/vLLM)
      linuxPackages.nvidia_x11

      # CUDA core runtime libraries
      cudaPackages.cuda_cudart
      cudaPackages.cuda_nvrtc
      cudaPackages.libcublas
      cudaPackages.libcufft
      cudaPackages.libcusparse
      cudaPackages.libcusolver
      cudaPackages.cudnn
      cudaPackages.nccl

      # Additional CUDA libraries for ML frameworks
      cudaPackages.libcurand
    ];
  };

  environment = {
    # System-level environment variables (used by system services)
    variables = {
      CARGO_HOME = "$HOME/.cargo";
    };

    # Session variables (available to all user shells and applications)
    sessionVariables = {
      # CUDA support for vLLM and other CUDA-dependent tools
      CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";

      # Library paths for CUDA linking (needed for FlashInfer JIT compilation)
      LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudatoolkit}/lib/stubs";

      # Triton CUDA library path (NixOS standard location for NVIDIA libs)
      TRITON_LIBCUDA_PATH = "/run/opengl-driver/lib";

      # Editor configuration
      EDITOR = "nvim";
    };

    # Note: User PATH is now managed by home-manager (see home/default.nix)
    # and nushell (see dotfiles/nushell/env.nu)
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = ["https://hyprland.cachix.org"];
    trusted-substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  # Performance CPU governor for development
  powerManagement.cpuFreqGovernor = "performance";

  # Host-specific services
  virtualisation.docker.enable = true;

  # Common services all hosts need
  services = {
    openssh.enable = true;
    printing.enable = true;
  };

  # Enable wireshark for packet capture capabilities (needed for arp-scan, etc)
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;

  system.stateVersion = "25.05";

  networking.networkmanager.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 18;
    consoleMode = "auto";
  };

  system.nixos.label = "";  # Disables the majority of the machine/os ID in the systemd boot entries

  boot.loader.efi.canTouchEfiVariables = true;

}
