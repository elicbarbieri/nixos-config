# Dell Desktop Configuration
# RTX 2070 Super - Dedicated GPU
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # sops-nix configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/age/keys.txt";
    secrets = {
      "nebula/ca-crt" = { owner = "nebula-mesh"; };
      "nebula/host-crt" = { owner = "nebula-mesh"; };
      "nebula/host-key" = { owner = "nebula-mesh"; };
    };
  };

  networking.hostName = "elicb-dell-desktop";

  # Ax-shell: only show bar on primary monitor (DP-1)
  programs.ax-shell.selectedMonitors = [ "DP-1" ];

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

  # EDID override for Sceptre F27 monitor on DP-3 (connected via DP->HDMI adapter)
  # Uses NixOS hardware.display module to generate EDID binary from modeline
  hardware.display.edid = {
    enable = true;
    modelines = {
      # Standard 1920x1080@60Hz timing (148.5 MHz pixel clock)
      "f27-1080p60" = "148.50  1920 2008 2052 2200  1080 1084 1089 1125 +hsync +vsync";
    };
  };

  # Apply EDID to DP-3 via kernel parameter (EDID binary auto-generated and installed as firmware)
  boot.kernelParams = [ "drm.edid_firmware=DP-3:edid/f27-1080p60.bin" ];

  # Docker firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "docker0" "br-+" ];  # Docker bridge interfaces
  };

  # User groups for this host
  users.users.elicb.extraGroups = [ "docker" "video" "render" "audio" "wireshark" "i2c" ];

  users.users.elicb.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgDA8a/EFrgf2Vzr7+Qnh1UBzu/l5xX1e/vMtNs1hiwdPCfjv/MisPidTlvU5X1tUvAGUZodX871FdnNX1EfRbWxX2kvURaM0GPJRhzCI+vmohH365qix4/HDUCVCFMGwDV8J6n3SgOYoOfGTOaFt+Q1Xmw8hHQfGOdxrh2AYWsGEjOhen4lPhZVDKzUB6+ZQmFnDWS9nd7ds8YOJ6ryxgdEICaD+rPSCDaRDJy5iHM4hyNITTm50pCR+oeYZ1Ay8q5ec3XEmpFGQSw4Roz5LV95TIfb0U7In8TTPGFrIPkxsvrEhBIdAVTcJXctHC4Ei2kOCAz0ArM0qA/L/Lpu7BNb/7eNHICEekTGx7v2tPqiE8+zTU8r7P2f5jWLcVYcJX8Xmj9xzBccR8Jo21+oujwo9Z2Yae94cdDkQeSQpASi/lZo7u7X7dfmUU70pypaDJhNwJv2GGRjRUPHFxVDMkRWJTGI0+QG8MoPMneOuolfOi7oSfrJ8/BrW3SlOOFgd73pvplZ4op/EwPCNKPgsig8oh24KOPxOD3C4hOPVr5OK7TVhG0KuHGeOkUgbtdC7RBcmwXWCKbmZ6xfrxXwvtuagWp5/6d3Cu96K2Q3dhVbh/DSaJH1uMKnEW0fsuB8xXj/YI5GrpaLIFNBpIibMiwOh3EJQQCawldKBJFRN3WQ== elicb@elicb-xps-wsl"
  ];

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
