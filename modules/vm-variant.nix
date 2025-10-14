# Generic VM variant configuration
# Apply to any host with: nixos-rebuild build-vm --flake .#hostname
{ config, lib, pkgs, ... }:

{
  virtualisation.vmVariant = {
    virtualisation.writableStore = true;
    virtualisation.writableStoreUseTmpfs = true;
    
    virtualisation.memorySize = 4096;
    virtualisation.cores = 4;
    virtualisation.diskSize = 10240;
    virtualisation.graphics = true;
    
    virtualisation.sharedDirectories = {
      nixos-config = {
        source = "/home/elicb/nixos-config";
        target = "/home/elicb/nixos-config";
      };
    };
    
    virtualisation.qemu.options = [
      "-display gtk,grab-on-hover=on"
      "-device virtio-keyboard-pci"
      "-k en-us"
    ];

    services.displayManager.autoLogin = {
      enable = lib.mkForce true;
      user = "elicb";
    };

    virtualisation.docker.enable = lib.mkForce false;
    
    # Disable disko for VMs - use virtualisation disk management instead
    disko.devices = lib.mkForce {};
  };
}
