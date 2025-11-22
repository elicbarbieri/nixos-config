# Gaming Specialization
# Maximum performance configuration for gaming

{ config, pkgs, lib, ... }:

{
  # NVIDIA performance - force sync mode for maximum gaming performance
  hardware.nvidia = {
    powerManagement.enable = lib.mkForce true;
    powerManagement.finegrained = lib.mkForce false;

    prime = {
      offload.enable = lib.mkForce false;
      offload.enableOffloadCmd = lib.mkForce false;
      sync.enable = lib.mkForce true;
    };
  };

  # High-impact kernel parameters for gaming performance
  boot.kernelParams = [
    "mitigations=off"  # Disable CPU mitigations for max FPS
    "i915.enable_dc=0"  # Disable Intel display power saving
  ];

  # TLP performance settings for gaming
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      USB_AUTOSUSPEND = 0;  # Prevent gaming peripheral disconnects
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
  ];

  programs.gamemode.enable = true;
}
