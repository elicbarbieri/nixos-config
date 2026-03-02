# Immich — self-hosted photo/video management
# Data stored on RAID5 array at /mnt/md0/immich
# Accessible via photos.barbieri.world (reverse proxy) and directly over Nebula
{ ... }:
{
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    mediaLocation = "/mnt/md0/immich";
    openFirewall = true;
  };

  systemd.services.immich-server = {
    after = [ "mnt-md0.mount" ];
    requires = [ "mnt-md0.mount" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/md0/immich 0750 immich immich -"
  ];
}
