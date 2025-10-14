# Gaming Specialization
# Maximum performance configuration for gaming

{ config, pkgs, lib, ... }:

{
  # Allow insecure packages required by Steam
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

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

  # Gaming packages
  environment.systemPackages = with pkgs; [
    steam
    lutris
    heroic
    gamemode
    gamescope
    mangohud
    
    # Minecraft dependencies
    (modrinth-app.overrideAttrs (oldAttrs: {
      buildCommand =
        ''
          gappsWrapperArgs+=(
             --set GDK_BACKEND x11
             --set WEBKIT_DISABLE_DMABUF_RENDERER 0
             --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}"
          )
        ''
        + oldAttrs.buildCommand;
    }))
    jdk
    glfw
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;
}
