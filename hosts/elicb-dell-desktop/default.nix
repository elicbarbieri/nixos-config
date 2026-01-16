# Dell Desktop Configuration
# RTX 2070 Super - Dedicated GPU
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  networking.hostName = "elicb-dell-desktop";

  # NVIDIA dedicated GPU configuration (no PRIME needed)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia-container-toolkit.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;  # Use proprietary driver for RTX 2070 Super
    nvidiaSettings = true;
    
    # No PRIME configuration needed - dedicated GPU only
    # prime.intelBusId and prime.nvidiaBusId intentionally not set
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Needed for 32-bit games and compatibility
  };

  # Docker firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "docker0" "br-+" ];  # Docker bridge interfaces
  };

  # User groups for this host
  users.users.elicb.extraGroups = [ "docker" "video" "render" "audio" "wireshark" ];

  # Gaming specialization only (no low-power or kubernetes for desktop)
  specialisation = {
    gaming = {
      inheritParentConfig = true;
      configuration = {
        imports = [ ../../modules/specializations/gaming.nix ];
      };
    };
  };
}
