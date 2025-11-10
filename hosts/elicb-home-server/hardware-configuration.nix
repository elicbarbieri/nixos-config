# Hardware configuration for elicb-home-server
# This is a placeholder - generate the actual configuration by running:
# nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
# on the target machine, then copy it here.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # TODO: Replace with actual hardware configuration
  # This placeholder allows the flake to build without errors
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
