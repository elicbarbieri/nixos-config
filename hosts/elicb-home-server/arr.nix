{ config, pkgs, ... }:
{
  # Shared media group for file access across all services
  users.groups.media = {};
  users.users.radarr.extraGroups = [ "media" ];
  users.users.sonarr.extraGroups = [ "media" ];
  users.users.lidarr.extraGroups = [ "media" ];
  users.users.bazarr.extraGroups = [ "media" ];
  users.users.deluge.extraGroups = [ "media" ];
  users.users.plex.extraGroups = [ "deluge" "media" ];

  # Directory structure (TRaSH Guides compliant)
  # setgid (02775) on downloads dirs so files inherit group 'media' regardless of
  # which service creates them — required for hardlinks to work across arr services
  # (sonarr runs with PrivateUsers=true, only 'media' GID is mapped in its user namespace)
  systemd.tmpfiles.rules = [
    "d /mnt/deepstor/media/downloads 02775 root media -"
    "d /mnt/deepstor/media/downloads/movies 02775 root media -"
    "d /mnt/deepstor/media/downloads/tv 02775 root media -"
    "d /mnt/deepstor/media/downloads/music 02775 root media -"
    "d /mnt/deepstor/media/library 02775 root media -"
    "d /mnt/deepstor/media/library/movies 02775 root media -"
    "d /mnt/deepstor/media/library/tv 02775 root media -"
    "d /mnt/deepstor/media/library/music 02775 root media -"
  ];

  # UMask=0002 so downloaded files are group-writable (664) — required for arr services
  # to hardlink them (sonarr/radarr need write access due to protected_hardlinks)
  systemd.services.deluged.serviceConfig.UMask = "0002";

  # Idle I/O class — BFQ yields disk to plex/ssh/file ops when they need it
  systemd.services.deluged.serviceConfig.IOSchedulingClass = "idle";
  systemd.services.sonarr.serviceConfig.IOSchedulingClass  = "idle";
  systemd.services.radarr.serviceConfig.IOSchedulingClass  = "idle";
  systemd.services.lidarr.serviceConfig.IOSchedulingClass  = "idle";

  # === Arr Services (native NixOS modules) ===

  services.prowlarr = { enable = true; openFirewall = true; };       # :9696
  services.radarr   = { enable = true; group = "media"; openFirewall = true; };  # :7878
  services.sonarr   = { enable = true; group = "media"; openFirewall = true; };  # :8989
  services.lidarr   = { enable = true; group = "media"; openFirewall = true; };  # :8686

  services.bazarr   = { enable = true; group = "media"; openFirewall = true; };  # :6767
  services.jellyseerr = { enable = true; openFirewall = true; };     # :5055

  # === Recyclarr (TRaSH Guides quality profiles) ===
  # Timer-based service that syncs quality profiles from TRaSH Guides
  # Config created after first launch of Radarr/Sonarr (need API keys)

  systemd.services.recyclarr = {
    description = "Recyclarr - TRaSH Guides sync";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.recyclarr}/bin/recyclarr sync";
      DynamicUser = true;
      StateDirectory = "recyclarr";
    };
  };

  systemd.timers.recyclarr = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # === Homarr Dashboard (Docker container) ===
  virtualisation.oci-containers.containers.homarr = {
    image = "ghcr.io/homarr-labs/homarr:latest";
    ports = [ "7575:7575" ];
    volumes = [
      "/var/lib/homarr:/appdata"
    ];
    environment = {
      TZ = "America/New_York";
    };
  };

  networking.firewall.allowedTCPPorts = [ 7575 58846 ];

  # === Deluge (torrent client) ===

  services.deluge = {
    enable = true;
    web.enable = true;
    declarative = true;
    config = {
      daemon_port = 58846;
      allow_remote = true;
      download_location = "/mnt/deepstor/media/downloads/";

      # Port forwarding (AirVPN forwarded ports: 24403-24407)
      listen_ports = [ 24403 24407 ];
      random_port = false;
      listen_interface = "0.0.0.0";

      max_active_limit = -1;              # Unlimited active torrents
      max_active_downloading = 10;         # 10 downloading simultaneously
      max_active_seeding = -1;             # Unlimited seeding

      max_connections_global = 100;        # Fewer peers — concentrate bandwidth on fast ones
      max_connections_per_torrent = 10;    # Tight per-torrent limit forces only fast peers to hold slots
      max_upload_slots_global = 50;        # 50 concurrent piece reads — keeps disk I/O manageable
      max_upload_slots_per_torrent = 3;    # 3 fast peers per torrent; fastest-upload algo picks best

      # Disable unnecessary features (manual port forwarding in use)
      upnp = false;                        # Disable UPnP
      natpmp = false;                      # Disable NAT-PMP

      dht = true;                          # Enable DHT
      utpex = true;                        # Enable peer exchange
      lsd = true;                          # Enable Local Service Discovery

      cache_size = 524288;      # 524288 * 16KiB = 8GB RAM cache — hot pieces served from RAM, not disk
      cache_expiry = 600;       # 10 min — keep hot pieces warm longer
      compact_allocation = false;  # pre-allocate full file size for contiguous layout on SMR drive
      seed_choking_algorithm = 1;  # fastest-upload: prioritize peers we can upload to fastest
      suggest_mode = 1;            # hint peers toward RAM-cached pieces, reduces disk reads on sdb
      enable_utp = false;          # force TCP for higher raw throughput

      enabled_plugins = [ "Label" ];
    };
    authFile = config.sops.secrets."deluge/auth".path;
  };

  # VPN-Confinement namespace for Deluge
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."airvpn/wireguard-conf".path;
    accessibleFrom = [
      "100.64.0.0/24"   # Nebula mesh network
      "127.0.0.1/32"    # localhost (radarr, sonarr, etc.)
    ];
    portMappings = [
      { from = 58846; to = 58846; protocol = "tcp"; }
      { from = 8112; to = 8112; protocol = "tcp"; }
    ];
    openVPNPorts = [
      { port = 24403; protocol = "both"; }
      { port = 24404; protocol = "both"; }
      { port = 24405; protocol = "both"; }
      { port = 24406; protocol = "both"; }
      { port = 24407; protocol = "both"; }
    ];
  };

  # vpn-confinement strips MTU from wireguard config; apply AirVPN's required 1320 after namespace setup
  systemd.services.wg.postStart = ''
    ${pkgs.iproute2}/bin/ip -n wg link set wg0 mtu 1320
  '';

  systemd.services.deluged.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  systemd.services.delugeweb.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };
}
