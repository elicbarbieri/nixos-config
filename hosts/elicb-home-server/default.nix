# Home Server Configuration
{ config, pkgs, nixvim, ... }:

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
      58846         # Deluge daemon port
      27020 27021 27022  # ARK RCON ports (Island, Scorched, Aberration)
    ];
    allowedUDPPorts = [
      7777 7778       # ARK Island (game + query)
      7779 7780       # ARK Scorched (game + query)
      7781 7782       # ARK Aberration (game + query)
    ];
  };

  # Additional groups for server functionality
  users.users.elicb.extraGroups = [ "docker" "deluge" "plex" ];

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

  # Allow Plex to read media files downloaded by Deluge
  users.users.plex.extraGroups = [ "deluge" "media" ];

  services.deluge = {
    enable = true;
    web.enable = false;
    declarative = true;
    config = {
      daemon_port = 58846;
      allow_remote = true;
      download_location = "/mnt/deepstor/media/downloads/";

      # Port forwarding (AirVPN forwarded ports: 24403-24407)
      listen_ports = [ 24403 24407 ];
      random_port = false;
      listen_interface = "0.0.0.0";
      outgoing_ports = [ 24403 24407 ];
      random_outgoing_ports = false;

      max_active_limit = -1;              # Unlimited active torrents
      max_active_downloading = 10;         # 10 downloading simultaneously
      max_active_seeding = -1;             # Unlimited seeding

      max_connections_global = 800;        # Total connections across all torrents
      max_connections_per_torrent = 100;   # Per-torrent connection limit
      max_upload_slots_global = -1;        # Unlimited global upload slots
      max_upload_slots_per_torrent = 8;    # 8 upload slots per torrent

      # Disable unnecessary features (manual port forwarding in use)
      upnp = false;                        # Disable UPnP
      natpmp = false;                      # Disable NAT-PMP

      dht = true;                          # Enable DHT
      utpex = true;                        # Enable peer exchange
      lsd = true;                          # Enable Local Service Discovery
    };
    authFile = config.sops.secrets."deluge/auth".path;
  };

  # VPN-Confinement namespace for Deluge
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."airvpn/wireguard-conf".path;
    accessibleFrom = [ "192.168.1.0/24" ];
    portMappings = [
      { from = 58846; to = 58846; protocol = "tcp"; }
    ];
    openVPNPorts = [
      { port = 24403; protocol = "both"; }
      { port = 24404; protocol = "both"; }
      { port = 24405; protocol = "both"; }
      { port = 24406; protocol = "both"; }
      { port = 24407; protocol = "both"; }
    ];
  };

  systemd.services.deluged.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  # Docker container backend (containers defined in ark.nix)
  virtualisation.oci-containers.backend = "docker";
}
