# Dell XPS 17 9730 Host Configuration
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

  # NVIDIA consumer drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  # nvidia-container-toolkit (CDI generator) is only needed for GPU host
  # containers; enabled in the kubernetes specialization to keep it off the
  # default boot's critical path (its cdi-generator service blocks
  # multi-user.target by ~4.6s at every boot).

  # This is a Modern-Standby (s2idle) only laptop — firmware exposes S0/S4/S5,
  # no S3 deep sleep. On Ada Optimus + s2idle the dGPU's KMS framebuffer does
  # not reliably re-scan-out on resume (intermittent black screen, fixed by a
  # lid toggle). Letting nvidia-drm own the fbdev console makes the framebuffer
  # restore on resume reliable. PreserveVideoMemoryAllocations is already on via
  # hardware.nvidia.powerManagement.enable below.
  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # Modern parallelized stage-1. Loads/starts units concurrently instead of the
  # scripted sequential initrd (which was ~11.4s here) and gives per-unit initrd
  # timing via `systemd-analyze`.
  # NOTE: initrd changes only take effect on a real reboot, NOT `nixos-rebuild
  # test`. If a boot ever hangs/black-screens, pick the previous generation from
  # the systemd-boot menu and remove this line. Verify resume-from-s2idle still
  # works (see the nvidia_drm.fbdev note above) after enabling.
  boot.initrd.systemd.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vpl-gpu-rt
    ];
  };

  # Host-specific session variables (merged with common.nix sessionVariables)
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";

    # Render Vulkan apps (GTK4, etc.) on the Intel iGPU, not the NVIDIA dGPU.
    #
    # GTK4's Vulkan renderer picks the *first* enumerated Vulkan device with no
    # discrete/integrated preference (gdk_display_create_vulkan_device). On this
    # hybrid laptop the NVIDIA ICD enumerates first, so every GTK4 Vulkan app
    # would render on the dGPU and PRIME-copy each frame to the iGPU (which drives
    # eDP-1). That cross-GPU presentation path stalls under Wayland (frozen UI
    # until input) and keeps the dGPU awake (battery/thermals).
    #
    # PRIME *offload* only governs OpenGL/GLX — it does NOT affect Vulkan device
    # enumeration — so the GPU must be selected explicitly here. The Mesa
    # device-select layer honours vendor:device; the trailing "!" *enforces* it
    # (without it the discrete GPU is still chosen). Games launched via
    # nvidia-offload override this with __VK_LAYER_NV_optimus=NVIDIA_only and
    # still use the dGPU. Intel Iris Xe (RPL-P) = 8086:a7a0.
    MESA_VK_DEVICE_SELECT = "8086:a7a0!";
  };

  # Host-specific configuration only
  networking.hostName = "elicb-xps";

  # Allow containers to access host services
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "docker0" "br-+" ]; # Docker bridge interfaces
  };

  # Additional groups for this host (base groups are in common.nix)
  users.users.elicb.extraGroups = [ "docker" "video" "render" "audio" "wireshark" "libvirtd" ];

  # keyd runs as a supervised root systemd service (Restart=always), so a glitch
  # self-heals instead of needing a manual kill/restart. It only grabs the
  # internal keyboard (0001:0001 = "AT Translated Set 2 keyboard"); external/ZSA
  # keyboards are left untouched, so no laptop-vs-external auto-detection is
  # needed. Confirm the id with `sudo keyd monitor` if a rebuild ever loses the
  # remap. See dotfiles/keyd-laptop/default.conf for the Colemak + nav layout.
  services.keyd.enable = true;
  services.keyd.keyboards.internal = {
    ids = [ "0001:0001" ];
    extraConfig = builtins.readFile ../../dotfiles/keyd-laptop/default.conf;
  };

  # Let wheel users start/stop/restart keyd.service without a password prompt,
  # so the Hyprland toggle hotkey is instant.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "keyd.service" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Fast Colemak on/off toggle (QWERTY passthrough) bound in Hyprland — a single
  # systemctl call, replacing the old multi-hundred-ms `nu` script pipeline.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "keyd-toggle" ''
      if systemctl is-active --quiet keyd; then
        systemctl stop keyd
        ${pkgs.libnotify}/bin/notify-send "keyd" "disabled (QWERTY)" --urgency=normal
      else
        systemctl start keyd
        ${pkgs.libnotify}/bin/notify-send "keyd" "enabled (Colemak + nav)" --urgency=normal
      fi
    '')
  ];

  services = {
    thermald.enable = true;
    fwupd.enable = true;
    hardware.bolt.enable = true; # Thunderbolt support
  };

  # Don't run the fwupd firmware-metadata refresh at boot (it was costing ~3s of
  # boot-time CPU/IO on the critical path). It still runs on its normal timer
  # while the machine is up; dropping Persistent just skips the catch-up run.
  systemd.timers.fwupd-refresh.timerConfig.Persistent = lib.mkForce false;

  # Specializations for different environments
  specialisation = {
    low-power = {
      inheritParentConfig = true;
      configuration = {
        imports = [ ../../modules/specializations/low-power.nix ];
      };
    };

    gaming = {
      inheritParentConfig = true;
      configuration = {
        imports = [ ../../modules/specializations/gaming.nix ];
        
        # XPS-specific: Force PRIME sync mode for maximum gaming performance
        hardware.nvidia.prime = {
          offload.enable = lib.mkForce false;
          offload.enableOffloadCmd = lib.mkForce false;
          sync.enable = lib.mkForce true;
        };
        
        # XPS-specific: Disable Intel display power saving for performance
        boot.kernelParams = [ "i915.enable_dc=0" ];
      };
    };

    # Laptop is a mesh CLIENT of the CRC cluster (which runs on the desktop), not
    # a CRC host: pull in the Nebula client (split-DNS + registry trust), not the
    # desktop's `specializations/kubernetes.nix` (crc/libvirt host config).
    kubernetes = {
      inheritParentConfig = true;
      configuration = {
        imports = [ ../../modules/crc-nebula-client.nix ];
      };
    };
  };


}
