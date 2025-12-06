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

      # sops-config = {
      #   source = "/home/elicb/.config/sops";
      #   target = "/home/elicb/.config/sops";
      # };

    };

    virtualisation.qemu.options = [
      "-display gtk,grab-on-hover=on"
      "-device virtio-keyboard-pci"
      "-k en-us"
    ];

    virtualisation.forwardPorts = [
      { from = "host"; host.port = 2222; guest.port = 22; }
    ];

    services.displayManager.autoLogin = {
      enable = lib.mkForce true;
      user = "elicb";
    };

    # Use bash in VMs for better TTY compatibility
    users.users.elicb.shell = lib.mkForce pkgs.bash;
    environment.shells = lib.mkForce [ pkgs.bash pkgs.nushell ];

    # Ensure firewall is disabled in VMs
    networking.firewall.enable = lib.mkForce false;

    virtualisation.docker.enable = lib.mkForce false;

    # Disable disko for VMs - use virtualisation disk management instead
    disko.devices = lib.mkForce {};

    # Disable nvidia configuration for VMs - VMs use virtual graphics
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;
    services.xserver.videoDrivers = lib.mkForce [];

    # Disable hypridle to prevent automatic lock attempts
    systemd.user.services.hypridle.enable = lib.mkForce false;
  };
}
