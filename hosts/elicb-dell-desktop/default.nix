# Dell Desktop Configuration
# RTX 2070 Super - Dedicated GPU
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

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
  # NOTE: drm.edid_firmware does NOT work with NVIDIA proprietary driver
  # Using debugfs workaround via systemd service instead
  hardware.display = {
    edid.modelines = {
      # Standard 1920x1080@60Hz timing (148.5 MHz pixel clock)
      "f27-1080p60" = "148.50  1920 2008 2052 2200  1080 1084 1089 1125 +hsync +vsync";
    };
    # Don't set outputs - we'll apply EDID via debugfs instead
  };

  # Systemd service to apply EDID override via debugfs (workaround for NVIDIA ignoring drm.edid_firmware)
  systemd.services.nvidia-edid-override = {
    description = "Apply custom EDID for Sceptre F27 monitor via debugfs";
    wantedBy = [ "graphical.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 2 && cat /run/current-system/firmware/edid/f27-1080p60.bin > /sys/kernel/debug/dri/1/DP-3/edid_override'";
    };
  };

  # Docker firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "docker0" "br-+" ];  # Docker bridge interfaces
  };

  # User groups for this host
  users.users.elicb.extraGroups = [ "docker" "video" "render" "audio" "wireshark" "i2c" ];

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
