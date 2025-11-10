# Low Power Specialization
# Battery optimization with LOW_POWER_MODE environment variable

{ config, pkgs, lib, ... }:

{
  # Set LOW_POWER_MODE environment variable
  environment.variables.LOW_POWER_MODE = "1";

  # Aggressive power saving
  powerManagement.cpuFreqGovernor = lib.mkForce "powersave";

  # Enable TLP for power management
  services.tlp.enable = true;

  # TLP power optimization
  services.tlp.settings = {
    # CPU scaling
    CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    
    # Intel P-State preferences
    CPU_ENERGY_PERF_POLICY_ON_AC = "power";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    
    # Platform profile
    PLATFORM_PROFILE_ON_AC = "low-power";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    
    # CPU boost
    CPU_BOOST_ON_AC = 0;
    CPU_BOOST_ON_BAT = 0;
    
    # CPU HWP hints
    CPU_HWP_DYN_BOOST_ON_AC = 0;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;
    
    # Aggressive PCIe power management
    PCIE_ASPM_ON_AC = "powersupersave";
    PCIE_ASPM_ON_BAT = "powersupersave";
    
    # Runtime power management
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
    
    # WiFi power saving
    WIFI_PWR_ON_AC = "on";
    WIFI_PWR_ON_BAT = "on";
    
    # Bluetooth power saving
    USB_AUTOSUSPEND = 1;
    USB_BLACKLIST_BTUSB = 0;
    
    # Disk power management
    DISK_APM_LEVEL_ON_AC = "128";
    DISK_APM_LEVEL_ON_BAT = "1";
    
    # SATA link power management
    SATA_LINKPWR_ON_AC = "med_power_with_dipm";
    SATA_LINKPWR_ON_BAT = "min_power";
  };

  # NVIDIA power management - disable GPU completely if present
  hardware.nvidia = lib.mkIf (config.hardware.nvidia.prime ? nvidiaBusId) {
    powerManagement.enable = lib.mkForce true;
    powerManagement.finegrained = lib.mkForce true;
    
    prime = {
      offload.enable = lib.mkForce true;
      offload.enableOffloadCmd = lib.mkForce true;
      sync.enable = lib.mkForce false;
    };
  };
  
  boot.extraModprobeConfig = lib.mkIf (config.hardware.nvidia.prime ? nvidiaBusId) ''
    options nvidia NVreg_DynamicPowerManagement=0x02
  '';

  # Reduce system services for power saving
  services = {
    # Disable unnecessary services
    
    # Reduce log retention
    journald.extraConfig = ''
      SystemMaxUse=100M
      RuntimeMaxUse=50M
    '';
  };

  # Kernel parameters for power saving
  boot.kernelParams = [
    # Intel graphics power saving
    "i915.enable_dc=2"
    "i915.enable_psr=1"
    
    # CPU power saving
    "intel_idle.max_cstate=2"
    
    # PCIe power saving
    "pcie_aspm=force"
    
    # Disable watchdog (saves power)
    "nowatchdog"
  ];

}
