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
  };


  # Host-specific configuration only
  networking.hostName = "elicb-xps";

  # Additional groups for this host (base groups are in common.nix)
  users.users.elicb.extraGroups = [ "docker" "video" "render" "audio" "keyd" ];

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
        imports = [ ../../specializations/low-power.nix ];
      };
    };
    
    gaming = {
      inheritParentConfig = true;
      configuration = {
        imports = [ ../../specializations/gaming.nix ];
      };
    };
  };


}
