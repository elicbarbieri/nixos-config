# System performance and maintenance module
{ pkgs, lib, ... }:

{
  # System maintenance and optimization
  services.fstrim.enable = true;
  
  nix = {
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };
  };

  # ZRAM swap with compression
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # Auto-tuning and performance monitoring
  services.bpftune.enable = true;
  programs.bcc.enable = true;

  # OOM management for nix-daemon
  systemd = {
    slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "95%";
    };
    services."nix-daemon" = {
      serviceConfig = {
        Slice = "nix-daemon.slice";
        OOMScoreAdjust = 1000;
      };
    };
  };

  # Default power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
  };
}