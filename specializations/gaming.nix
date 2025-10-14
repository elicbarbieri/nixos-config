# Gaming Specialization
# Maximum performance configuration for gaming and streaming

{ config, pkgs, lib, ... }:

{
  # Performance CPU governor
  powerManagement.cpuFreqGovernor = "performance";

  # Enable TLP for power management
  services.tlp.enable = true;

  # TLP performance optimization
  services.tlp.settings = {
    # CPU scaling
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "performance";
    
    # Intel P-State preferences
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "performance";
    
    # Platform profile
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "performance";
    
    # CPU boost
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 1;
    
    # CPU HWP hints
    CPU_HWP_DYN_BOOST_ON_AC = 1;
    CPU_HWP_DYN_BOOST_ON_BAT = 1;
    
    # Minimal PCIe power management
    PCIE_ASPM_ON_AC = "default";
    PCIE_ASPM_ON_BAT = "default";
    
    # Disable runtime power management for performance
    RUNTIME_PM_ON_AC = "on";
    RUNTIME_PM_ON_BAT = "on";
    
    # WiFi performance
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "off";
    
    # Disable USB autosuspend for gaming peripherals
    USB_AUTOSUSPEND = 0;
    
    # Disk performance
    DISK_APM_LEVEL_ON_AC = "254";
    DISK_APM_LEVEL_ON_BAT = "254";
    
    # SATA link power management
    SATA_LINKPWR_ON_AC = "max_performance";
    SATA_LINKPWR_ON_BAT = "max_performance";
  };

  # NVIDIA performance - always use NVIDIA GPU if present
  hardware.nvidia = lib.mkIf (config.hardware.nvidia.prime ? nvidiaBusId) {
    powerManagement.enable = lib.mkForce true;
    powerManagement.finegrained = lib.mkForce false;
    
    prime = {
      offload.enable = lib.mkForce false;
      sync.enable = lib.mkForce true;
    };
  };

  # Gaming-specific kernel parameters
  boot.kernelParams = [
    # Disable CPU mitigations for performance (security trade-off)
    "mitigations=off"
    
    # Intel graphics performance
    "i915.enable_dc=0"
    "i915.enable_psr=0"
    
    # CPU performance
    "intel_idle.max_cstate=1"
    
    # Memory performance
    "transparent_hugepage=always"
    
    # Scheduler optimization for gaming
    "preempt=voluntary"
  ];

  # Additional gaming packages
  environment.systemPackages = with pkgs; [
    steam
    lutris
    heroic
    gamemode
    gamescope
    mangohud
    goverlay
  ];



  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Enable GameMode
  programs.gamemode.enable = true;

  # Performance optimizations
  boot.kernel.sysctl = {
    # Gaming-specific optimizations
    "kernel.sched_autogroup_enabled" = 0;
    "kernel.sched_child_runs_first" = 0;
  };

  # Increase inotify limits for development tools
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 1048576;

  services = {
    # Disable power-saving services that might interfere
    power-profiles-daemon.enable = false;
  };
}
