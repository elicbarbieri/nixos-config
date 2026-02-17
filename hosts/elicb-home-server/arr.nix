{ config, pkgs, ... }:
{
  # Shared media group for file access across all services
  users.groups.media = {};
  users.users.radarr.extraGroups = [ "media" ];
  users.users.sonarr.extraGroups = [ "media" ];
  users.users.lidarr.extraGroups = [ "media" ];
  users.users.bazarr.extraGroups = [ "media" ];
  users.users.deluge.extraGroups = [ "media" ];
  users.users.plex.extraGroups = [ "media" ];

  # Directory structure (TRaSH Guides compliant)
  systemd.tmpfiles.rules = [
    "d /mnt/deepstor/media/downloads 0775 root media -"
    "d /mnt/deepstor/media/downloads/movies 0775 root media -"
    "d /mnt/deepstor/media/downloads/tv 0775 root media -"
    "d /mnt/deepstor/media/downloads/music 0775 root media -"
    "d /mnt/deepstor/media/library 0775 root media -"
    "d /mnt/deepstor/media/library/movies 0775 root media -"
    "d /mnt/deepstor/media/library/tv 0775 root media -"
    "d /mnt/deepstor/media/library/music 0775 root media -"
  ];

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

  networking.firewall.allowedTCPPorts = [ 7575 ];
}
