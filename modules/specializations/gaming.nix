# Gaming Specialization
# Maximum performance configuration for gaming
# Automatically adapts for laptop (hybrid graphics) vs desktop (dedicated GPU)

{ config, pkgs, lib, ... }:

let
  # Detect if system has PRIME configured (hybrid graphics laptop)
  hasPrime = (config.hardware.nvidia.prime.intelBusId or "") != "" 
          || (config.hardware.nvidia.prime.amdgpuBusId or "") != "";
  
  # Detect if system is likely a laptop (has thermald or battery TLP settings)
  isLaptop = config.services.thermald.enable or false;
in
{
  # NVIDIA performance configuration
  hardware.nvidia = {
    powerManagement.enable = lib.mkForce true;
    powerManagement.finegrained = lib.mkForce false;
  } // lib.optionalAttrs hasPrime {
    # Only configure PRIME sync mode if PRIME is available
    # For dedicated GPUs, these settings are not needed
    prime = {
      offload.enable = lib.mkForce false;
      offload.enableOffloadCmd = lib.mkForce false;
      sync.enable = lib.mkForce true;
    };
  };

  # High-impact kernel parameters for gaming performance
  boot.kernelParams = [
    "mitigations=off"  # Disable CPU mitigations for max FPS
  ] ++ lib.optionals hasPrime [
    # Only disable Intel display power saving if using Intel hybrid graphics
    "i915.enable_dc=0"
  ];

  # Disable power-profiles-daemon (conflicts with TLP)
  services.power-profiles-daemon.enable = lib.mkForce false;

  # TLP performance settings for gaming
  services.tlp = {
    enable = true;
    settings = {
      CPU_BOOST_ON_AC = 1;
      USB_AUTOSUSPEND = 0;  # Prevent gaming peripheral disconnects
      PLATFORM_PROFILE_ON_AC = "performance";   # Uncap GPU power
    } // lib.optionalAttrs isLaptop {
      # Battery-specific settings only for laptops
      CPU_BOOST_ON_BAT = 1;
      PLATFORM_PROFILE_ON_BAT = "performance";  # Uncap GPU power on battery too
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
