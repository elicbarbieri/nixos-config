# Dell XPS 17 9730
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/age/keys.txt";
    secrets = {
      "nebula/ca-crt" = { owner = "nebula-mesh"; };
      "nebula/host-crt" = { owner = "nebula-mesh"; };
      "nebula/host-key" = { owner = "nebula-mesh"; };
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # s2idle-only laptop (firmware exposes S0/S4/S5, no S3). Ada Optimus + s2idle → dGPU KMS
  # framebuffer does not reliably re-scan-out on resume (black screen until lid toggle).
  # nvidia-drm owning fbdev makes the restore reliable.
  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # parallel stage-1, replaces the ~11.4s scripted initrd; gives per-unit initrd timing
  # - takes effect on real reboot only, NOT `nixos-rebuild test`
  # - on hang/black-screen: previous generation from the systemd-boot menu, drop this line
  boot.initrd.systemd.enable = true;

  # no LVM in stage 1 (root = btrfs): initrd autoactivated ztest, switch-root killed its thin_check
  # mid-run → pool left inactive with thin_tmeta/thin_tdata active, topolvm dead until manual fix
  boot.initrd.services.lvm.enable = false;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;  # → PreserveVideoMemoryAllocations, see fbdev note above
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

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";

    # Vulkan onto the iGPU (Intel Iris Xe RPL-P = 8086:a7a0), which drives eDP-1.
    #
    # - GTK4 picks the first enumerated device, no discrete/integrated preference; NVIDIA ICD
    #   enumerates first → every GTK4 app renders on the dGPU + PRIME-copies each frame
    # - that cross-GPU present stalls under Wayland (frozen UI until input), keeps dGPU awake
    # - PRIME offload governs OpenGL/GLX only, does NOT affect Vulkan enumeration
    # - trailing `!` enforces; without it the discrete GPU still wins
    # - nvidia-offload overrides via __VK_LAYER_NV_optimus=NVIDIA_only, so games keep the dGPU
    MESA_VK_DEVICE_SELECT = "8086:a7a0!";
  };

  networking.hostName = "elicb-xps";

  # authenticate once with `sudo tailscale up`
  # --accept-dns=false + ts.net delegation live in modules/networking.nix
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # only roaming host (server never sees a portal), and the option needs a concrete interface
  networking.hostile = {
    enable = true;
    interface = "wlp0s20f3";
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "docker0" "br-+" "tailscale0" ];
  };

  users.users.elicb.extraGroups = [ "docker" "video" "render" "audio" "wireshark" "libvirtd" ];

  # LAN drops multicast -> discovers nothing, but still resurrects deleted queues (implicitclass://)
  services.printing.browsed.enable = false;

  hardware.printers = {
    ensureDefaultPrinter = "Canon_LBP646C_UFR2";
    ensurePrinters = [
      {
        name = "Canon_LBP646C_UFR2";
        description = "Canon LBP646C UFR II";
        location = "LAN (static on printer: 172.16.100.163, 20:0b:74:b1:ee:b5)";
        # IP, never .local (AP drops multicast -> mDNS dead here; unicast fine, so pin the address)
        deviceUri = "socket://172.16.100.163:9100";
        model = "CNRCUPSLBP646CZS.ppd";
        ppdOptions = {
          # 1200 only via UFR2 (IPP driverless caps at 300 = printer-resolution-supported)
          Resolution = "1200";
          PageSize = "Letter";
          CNColorMode = "color"; # Auto = per-page mono fallback
          CNTonerSaving = "False"; # Auto (= PPD default) still throttles
        };
      }
    ];
  };

  # Restart=always → a glitch self-heals without a manual kill
  # 0001:0001 = internal AT keyboard only; external/ZSA untouched (`sudo keyd monitor` to confirm)
  services.keyd.enable = true;
  services.keyd.keyboards.internal = {
    ids = [ "0001:0001" ];
    extraConfig = builtins.readFile ../../dotfiles/keyd-laptop/default.conf;
  };

  # passwordless keyd start/stop for wheel → instant Hyprland toggle hotkey
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "keyd.service" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Colemak on/off (QWERTY passthrough), bound in Hyprland
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
    # ztest VG (topolvm thin pool) → stage-2 lvm.conf thin_check/thin_repair paths for activation
    lvm.boot.thin.enable = true;
    thermald.enable = true;
    fwupd.enable = true;
    hardware.bolt.enable = true;
  };

  # firmware-metadata refresh cost ~3s of boot CPU/IO; timer still runs while up, only the
  # catch-up run is dropped
  systemd.timers.fwupd-refresh.timerConfig.Persistent = lib.mkForce false;

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

        hardware.nvidia.prime = {
          offload.enable = lib.mkForce false;
          offload.enableOffloadCmd = lib.mkForce false;
          sync.enable = lib.mkForce true;
        };

        boot.kernelParams = [ "i915.enable_dc=0" ];
      };
    };
  };
}
