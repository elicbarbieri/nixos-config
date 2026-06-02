# Home Server Configuration
{ config, pkgs, lib, nixvim, simplex-chat, ... }:

let
  base-packages = import ../../modules/base-packages.nix { inherit pkgs nixvim; };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./ark.nix
    ./arr.nix
    ./minecraft.nix
    ./musicbrainz.nix
    ./immich.nix
    ./simplex.nix
  ];

  # sops-nix configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/age/keys.txt";
    secrets = {
      "deluge/auth" = {
        owner = "deluge";
        group = "deluge";
        mode = "0600";
        restartUnits = [ "deluged.service" ];
      };
      "airvpn/wireguard-conf" = {
        mode = "0400";
      };
      "ark/admin-password" = {};
      "ark/server-password" = {};
      "nebula/ca-crt" = { owner = "nebula-mesh"; };
      "nebula/host-crt" = { owner = "nebula-mesh"; };
      "nebula/host-key" = { owner = "nebula-mesh"; };
    };

  };

  # UUID: b0de9c80:a5ac423d:61f20052:ba33e57e (RAID array UUID)
  # Filesystem UUID: d9b99d85-6a26-4637-b8db-342f465b58f8
  fileSystems."/mnt/md0" = {
    device = "/dev/disk/by-uuid/d9b99d85-6a26-4637-b8db-342f465b58f8";
    fsType = "ext4";
  };

  fileSystems."/mnt/deepstor" = {
    device = "/dev/disk/by-label/deepstor";
    fsType = "ext4";
  };

  # BFQ I/O scheduler for sdb (SMR HDD) — much better for mixed random read/write workloads
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sdb", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sdb", ATTR{queue/read_ahead_kb}="256"
    ACTION=="add|change", KERNEL=="sdb", ATTR{queue/iosched/low_latency}="0"
  '';

  # Enable mdadm for RAID5 array management
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    ARRAY /dev/md0 UUID=b0de9c80:a5ac423d:61f20052:ba33e57e
  '';

  environment.systemPackages = base-packages.common ++ (with pkgs; [
    btrfs-progs
  ]);

  networking.hostName = "elicb-home-server";

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      27020 27021 27022  # ARK RCON ports (Island, Scorched, Aberration)
    ];
    allowedUDPPorts = [
      7777 7778       # ARK Island (game + query)
      7779 7780       # ARK Scorched (game + query)
      7781 7782       # ARK Aberration (game + query)
    ];
  };

  # Additional groups for server functionality
  users.users.elicb.extraGroups = [ "docker" "deluge" "plex" "media" ];

  users.users.elicb.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgDA8a/EFrgf2Vzr7+Qnh1UBzu/l5xX1e/vMtNs1hiwdPCfjv/MisPidTlvU5X1tUvAGUZodX871FdnNX1EfRbWxX2kvURaM0GPJRhzCI+vmohH365qix4/HDUCVCFMGwDV8J6n3SgOYoOfGTOaFt+Q1Xmw8hHQfGOdxrh2AYWsGEjOhen4lPhZVDKzUB6+ZQmFnDWS9nd7ds8YOJ6ryxgdEICaD+rPSCDaRDJy5iHM4hyNITTm50pCR+oeYZ1Ay8q5ec3XEmpFGQSw4Roz5LV95TIfb0U7In8TTPGFrIPkxsvrEhBIdAVTcJXctHC4Ei2kOCAz0ArM0qA/L/Lpu7BNb/7eNHICEekTGx7v2tPqiE8+zTU8r7P2f5jWLcVYcJX8Xmj9xzBccR8Jo21+oujwo9Z2Yae94cdDkQeSQpASi/lZo7u7X7dfmUU70pypaDJhNwJv2GGRjRUPHFxVDMkRWJTGI0+QG8MoPMneOuolfOi7oSfrJ8/BrW3SlOOFgd73pvplZ4op/EwPCNKPgsig8oh24KOPxOD3C4hOPVr5OK7TVhG0KuHGeOkUgbtdC7RBcmwXWCKbmZ6xfrxXwvtuagWp5/6d3Cu96K2Q3dhVbh/DSaJH1uMKnEW0fsuB8xXj/YI5GrpaLIFNBpIibMiwOh3EJQQCawldKBJFRN3WQ== elicb@elicb-xps-wsl"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWLRxmInzcSvWIS+WEQ6wslR1tB6PtcU8Cr0L1Qn9qD elicb@dell-desktop"
  ];

  virtualisation.docker.enable = true;

  # Plex Media Server
  services.plex = {
    enable = true;
    openFirewall = true;  # Opens port 32400 and other Plex ports for remote access
    dataDir = "/var/lib/plex";  # Metadata, database, and transcoding cache
  };

  # PrivateTmp isolates /tmp from child processes — EAE watchfolder fails without a stable path
  systemd.services.plex.serviceConfig.PrivateTmp = lib.mkForce false;
  systemd.tmpfiles.rules = [
    "d /var/lib/plex/tmp 0755 plex plex -"
  ];
  systemd.services.plex.environment = {
    TMPDIR = "/var/lib/plex/tmp";
  };

  # Nebula lighthouse
  nebula.isLighthouse = true;

  # Docker container backend (containers defined in ark.nix)
  virtualisation.oci-containers.backend = "docker";
}
