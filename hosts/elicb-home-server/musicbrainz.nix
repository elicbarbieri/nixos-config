# MusicBrainz Database Mirror
# Mirrors the MusicBrainz PostgreSQL database via mbslave replication.
# No search indexes (Solr) - data-only mirror for direct client queries.
#
# One-time setup after first deploy:
#   1. Add secrets: sops hosts/elicb-home-server/secrets.yaml
#      - musicbrainz/replication-token: from https://metabrainz.org profile
#      - musicbrainz/db-password: password for remote PostgreSQL access
#   2. Initialize the database:
#      sudo -u postgres MBSLAVE_CONFIG=/etc/mbslave.conf \
#        MBSLAVE_MUSICBRAINZ_TOKEN=$(sudo cat /run/secrets/musicbrainz/replication-token) \
#        mbslave init
#   3. Replication syncs automatically every hour after that.
{ config, pkgs, lib, ... }:

let
  mbslave = pkgs.python3Packages.buildPythonApplication rec {
    pname = "mbslave";
    version = "28.0.0";
    src = pkgs.fetchFromGitHub {
      owner = "acoustid";
      repo = "mbslave";
      rev = "v${version}";
      hash = "sha256-aZMyOJyE1rhMb1OrlBOwEtypHHlC1OtJpMjluRR6zgY=";
    };
    pyproject = true;
    build-system = [ pkgs.python3Packages.poetry-core ];
    dependencies = with pkgs.python3Packages; [
      psycopg2
      six
      prometheus-client
    ];
  };

  mbslaveConfig = pkgs.writeText "mbslave.conf" ''
    [database]
    name=musicbrainz
    user=postgres

    [musicbrainz]
    base_url=https://metabrainz.org/api/musicbrainz/

    [tables]
    ignore=

    [schemas]
    musicbrainz=musicbrainz
    statistics=statistics
    cover_art_archive=cover_art_archive
    event_art_archive=event_art_archive
    wikidocs=wikidocs
    documentation=documentation
    dbmirror2=dbmirror2
  '';
in
{
  # ---------------------------------------------------------------------------
  # PostgreSQL - data on RAID array
  # ---------------------------------------------------------------------------
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    dataDir = "/mnt/md0/postgresql";
    enableTCPIP = true;

    # Allow remote clients to connect as musicbrainz user with password
    authentication = lib.mkAfter ''
      host musicbrainz musicbrainz 0.0.0.0/0 scram-sha-256
    '';

    ensureDatabases = [ "musicbrainz" ];
    ensureUsers = [{
      name = "musicbrainz";
      ensureDBOwnership = true;
    }];

    settings = {
      shared_buffers = "2GB";
      effective_cache_size = "6GB";
      work_mem = "256MB";
      maintenance_work_mem = "512MB";
    };
  };

  # PostgreSQL must wait for RAID mount
  systemd.services.postgresql = {
    after = [ "mnt-md0.mount" ];
    requires = [ "mnt-md0.mount" ];
  };

  # Ensure data directory exists with correct ownership
  systemd.tmpfiles.rules = [
    "d /mnt/md0/postgresql 0700 postgres postgres -"
  ];

  # ---------------------------------------------------------------------------
  # Database setup - extensions + remote access password
  # ---------------------------------------------------------------------------
  systemd.services.musicbrainz-db-setup = {
    description = "MusicBrainz PostgreSQL extensions and user setup";
    after = [ "postgresql.service" "postgresql-setup.service" ];
    requires = [ "postgresql.service" "postgresql-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      ExecStart = let psql = "${config.services.postgresql.package}/bin/psql"; in
        pkgs.writeShellScript "musicbrainz-db-setup" ''
          ${psql} -d musicbrainz -c "CREATE EXTENSION IF NOT EXISTS cube;"
          ${psql} -d musicbrainz -c "CREATE EXTENSION IF NOT EXISTS earthdistance;"
          PW=$(cat ${config.sops.secrets."musicbrainz/db-password".path})
          ${psql} -c "ALTER ROLE musicbrainz WITH PASSWORD '$PW';"
        '';
    };
  };

  # ---------------------------------------------------------------------------
  # Replication sync - hourly via mbslave
  # ---------------------------------------------------------------------------
  systemd.services.musicbrainz-sync = {
    description = "MusicBrainz database replication sync";
    after = [ "postgresql.service" "musicbrainz-db-setup.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = pkgs.writeShellScript "musicbrainz-sync" ''
        export MBSLAVE_CONFIG=${mbslaveConfig}
        export MBSLAVE_MUSICBRAINZ_TOKEN=$(cat ${config.sops.secrets."musicbrainz/replication-token".path})
        exec ${mbslave}/bin/mbslave sync
      '';
    };
  };

  systemd.timers.musicbrainz-sync = {
    description = "MusicBrainz hourly replication sync";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  # ---------------------------------------------------------------------------
  # mbslave config file for manual operations
  # ---------------------------------------------------------------------------
  environment.etc."mbslave.conf".source = mbslaveConfig;

  # ---------------------------------------------------------------------------
  # Secrets
  # ---------------------------------------------------------------------------
  sops.secrets."musicbrainz/replication-token" = {
    owner = "postgres";
    mode = "0400";
  };
  sops.secrets."musicbrainz/db-password" = {
    owner = "postgres";
    mode = "0400";
  };

  # ---------------------------------------------------------------------------
  # Firewall & packages
  # ---------------------------------------------------------------------------
  networking.firewall.allowedTCPPorts = [ 5432 ];
  environment.systemPackages = [ mbslave ];
}
