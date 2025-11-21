# Dell XPS 17 9730 Host Configuration
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # NVIDIA Configuration for RTX 4080 Mobile
  services.xserver.videoDrivers = [ "nvidia" ];
  
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
  };


  # Host-specific configuration only
  networking.hostName = "elicb-xps";
  
  # Use latest stable kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Allow containers to access host services
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "docker0" "br-+" "cni+" ]; # Docker and Kubernetes CNI interfaces
    allowedTCPPorts = [ 
      6443  # Kubernetes API server
      10250 # Kubelet API
    ];
    allowedUDPPorts = [ 
      8472  # Flannel VXLAN
    ];
  };

  # Additional groups for this host (base groups are in common.nix)
  users.users.elicb.extraGroups = [ "docker" "video" "render" "audio" "keyd" "wireshark" ];

  users.groups.keyd = {};

  security.wrappers.keyd = {
    source = "${pkgs.keyd}/bin/keyd";
    owner = "root";
    group = "keyd";
    setuid = true;
  };

  environment.etc."keyd/default.conf".source = ../../dotfiles/keyd-laptop/default.conf;

  # Host-specific services
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  
  # Kubernetes (k3s)
  services.k3s = {
    enable = true;
    role = "server";
  };
  
  services = {
    thermald.enable = true;
    fwupd.enable = true;
    hardware.bolt.enable = true; # Thunderbolt support
  };

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
      };
    };
  };


}
