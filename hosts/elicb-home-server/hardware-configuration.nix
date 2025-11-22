# Hardware configuration for elicb-home-server
# Minimal configuration - all filesystems managed by disko-config.nix and default.nix

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Kernel modules - update these after running nixos-generate-config during installation
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
