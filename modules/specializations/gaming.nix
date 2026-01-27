# Gaming Specialization
# Maximum performance configuration for gaming
# Host-specific hardware overrides (like PRIME sync) should be in host config

{ config, pkgs, lib, ... }:

{
  # NVIDIA performance configuration
  hardware.nvidia = {
    powerManagement.enable = lib.mkForce true;
    powerManagement.finegrained = lib.mkForce false;
  };

  # High-impact kernel parameters for gaming performance
  boot.kernelParams = [
    "mitigations=off"  # Disable CPU mitigations for max FPS
  ];

  # Disable power-profiles-daemon (conflicts with TLP)
  services.power-profiles-daemon.enable = lib.mkForce false;

  # TLP performance settings for gaming
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      USB_AUTOSUSPEND = 0;  # Prevent gaming peripheral disconnects
      PLATFORM_PROFILE_ON_AC = "performance";   # Uncap GPU power
      PLATFORM_PROFILE_ON_BAT = "performance";  # Uncap GPU power on battery
    };
  };

  # Steam configuration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud

    prismlauncher

    heroic
  ];

  programs.gamemode.enable = true;
}
