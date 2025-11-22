# Generic VM variant configuration
# Apply to any host with: nixos-rebuild build-vm --flake .#hostname
{ config, lib, pkgs, ... }:

{
  virtualisation.vmVariant = {
    # Make hyprlock a no-op in VMs
    # This provides a dummy hyprlock that doesn't lock the screen
    environment.systemPackages = lib.mkBefore [
      (pkgs.writeShellScriptBin "hyprlock" ''
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  hyprlock is disabled in VM environment"
        echo "  This is a NixOS VM - screen locking is not needed"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      '')
    ];

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
      "-nic user,hostfwd=tcp::2222-:22"
    ];

    services.displayManager.autoLogin = {
      enable = lib.mkForce true;
      user = "elicb";
    };

    virtualisation.docker.enable = lib.mkForce false;
    
    # Disable disko for VMs - use virtualisation disk management instead
    disko.devices = lib.mkForce {};
    
    # Disable nvidia configuration for VMs - VMs use virtual graphics
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;
    services.xserver.videoDrivers = lib.mkForce [];

    # Disable hypridle to prevent automatic lock attempts
    systemd.user.services.hypridle.enable = lib.mkForce false;

    # Disable services that require secrets in VMs (for elicb-home-server)
    systemd.services."netns@".enable = lib.mkForce false;
    systemd.services.wg.enable = lib.mkForce false;
    
    # Remove bindings for services that depend on disabled services
    systemd.services.deluged.bindsTo = lib.mkForce [];
    systemd.services.deluged.requires = lib.mkForce [ "network-online.target" ];
    systemd.services.deluged.serviceConfig.NetworkNamespacePath = lib.mkForce [];
  };
}
