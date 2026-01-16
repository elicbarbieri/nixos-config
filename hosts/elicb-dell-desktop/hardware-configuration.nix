# Hardware Configuration for Dell Desktop
# TODO: Generate this file on the actual machine using:
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# This placeholder provides the minimal structure needed for now.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: Replace with actual boot configuration
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];  # Change to "kvm-amd" if AMD CPU
  boot.extraModulePackages = [ ];

  # Filesystems are managed by disko-config.nix
  fileSystems."/" = lib.mkDefault { device = "none"; fsType = "none"; };
  
  # TODO: The following will be auto-generated and should include:
  #   - Correct kernel modules for your hardware
  #   - CPU microcode (intel or amd)
  #   - Any special hardware configurations
  #   - Network interfaces
  
  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # OR for AMD: hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
