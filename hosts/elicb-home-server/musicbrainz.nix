# MusicBrainz + AcoustID Audio Fingerprinting Server
#
# COMPONENTS:
#   - MusicBrainz: PostgreSQL database with music metadata (~45 GB)
#     Managed via official MusicBrainz Docker (database-only mirror mode)
#   - AcoustID: Audio fingerprint → MusicBrainz ID matching (~35 GB)
#   - acoustid-index: Fast fingerprint search engine (HTTP API on :8081)
#
# INITIAL SETUP:
#   1. Deploy config, then initialize MusicBrainz database:
#      $ cd /opt/musicbrainz-docker && docker compose run --rm musicbrainz createdb.sh -fetch
#      This loads into host PostgreSQL (not Docker) via docker-compose.host-db.yml override.
#      Monitor: docker compose logs -f
#
#   2. AcoustID fingerprint database:
#      $ sudo systemctl start acoustid-init
#      $ journalctl -u acoustid-init -f
#
# ARCHITECTURE:
#   - PostgreSQL runs natively on NixOS (not in Docker)
#   - MusicBrainz Docker tools connect to host PostgreSQL via docker0 IP
#   - Database-only mirror mode (no web server overhead)
#   - Official MusicBrainz tooling ensures schema compatibility
#
# ONGOING MAINTENANCE:
#   - MusicBrainz sync: hourly (musicbrainz-docker-replication.timer)
#   - AcoustID sync: daily (acoustid-sync.timer)
#
# ACOUSTID LOOKUP API:
#   POST http://localhost:8081/acoustid/_search
#   {"query": [fingerprint_hashes], "limit": 10}
{ config, pkgs, lib, ... }:

let
  musicbrainzDockerRoot = "/opt/musicbrainz-docker";

  # ---------------------------------------------------------------------------
  # acoustid-index: Fast fingerprint search engine (Zig)
  # ---------------------------------------------------------------------------
  acoustid-index = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "acoustid-index";
    version = "2025-10-27";

    src = pkgs.fetchFromGitHub {
      owner = "acoustid";
      repo = "acoustid-index";
      rev = "6bc929a316e4f3a9c9ec37a395f30e0f5b7116c2";
      hash = "sha256-hqWsbQEEs02p3UOuR5zptKE60GxSPvVoysrrtXx7nyc=";
    };

    deps = pkgs.linkFarm "zig-packages" [
      {
        name = "httpz-0.0.0-PNVzrJSuBgDFvO7mtd2qDzaq8_hXIu1BqFuL1jwAV8Ac";
        path = pkgs.fetchFromGitHub {
          owner = "karlseguin";
          repo = "http.zig";
          rev = "56258131ef4505543fef5484451867c13c5ff322";
          hash = "sha256-e6tzbYDdYlgg1riBfblK899OFLFe4dNan5/B24tEjLk=";
        };
      }
      {
        name = "zul-0.0.0-1oDot0BCBwA9cUo5OOrPs5NGmvoM7sk1ztfbdfL7mh4P";
        path = pkgs.fetchFromGitHub {
          owner = "karlseguin";
          repo = "zul";
          rev = "d9142c73aedc5698beba58b3fbf2bcfe69864778";
          hash = "sha256-kQ1nOdSw0sNAOSMYgEBgNLE4XFGe4h9hGWOYMFKrzqA=";
        };
      }
      {
        name = "122061f30077ef518dd435d397598ab3c45daa3d2c25e6b45383fb94d0bd2c3af1af";
        path = pkgs.fetchFromGitHub {
          owner = "karlseguin";
          repo = "metrics.zig";
          rev = "cf2797bcb3aea7e5cdaf4de39c5550c70796e7b1";
          hash = "sha256-9wb9pU3jTXfZYaQzPuW0IrsftJTyRCJfG9oks6RpKy4=";
        };
      }
      {
        name = "msgpack-0.3.0-ZOu9PO3MAQDvMwnQWWG6_tskPegFXF7gV9OA7EyMwEai";
        path = pkgs.fetchFromGitHub {
          owner = "lalinsky";
          repo = "msgpack.zig";
          rev = "094f0b1a6fcf3ae4867d06dd9e6b69f40e8dd56e";
          hash = "sha256-i6Vih7vvHuIj7egi6NvdxPEur8wWFpon7QV1PlAo7YY=";
        };
      }
      {
        name = "nats-0.0.0-JvIiUFIMBwCd5EjU1IAdOufjmn8-6MboloGoPSJfD_J9";
        path = pkgs.fetchFromGitHub {
          owner = "lalinsky";
          repo = "nats.zig";
          rev = "6937d6eeffcfbd52703557f5b12e2a7f2c5cf65e";
          hash = "sha256-7cibpPWEskGxokRt/WBCEJynlTLgazac8QW309VrLwY=";
        };
      }
      {
        name = "websocket-0.1.0-ZPISdXNIAwCXG7oHBj4zc1CfmZcDeyR6hfTEOo8_YI4r";
        path = pkgs.fetchFromGitHub {
          owner = "karlseguin";
          repo = "websocket.zig";
          rev = "7c3f1149bffcde1dec98dea88a442e2b580d750a";
          hash = "sha256-qyfeyR3Yp5i1YROqaOp4QP8U0rYCXgdeeUKbbXQJMU4=";
        };
      }
      {
        name = "1220971bba07063e3373509f9997037b247a85f4c43a8f3f608e2b25d241fb72dd6d";
        path = pkgs.fetchFromGitHub {
          owner = "karlseguin";
          repo = "websocket.zig";
          rev = "7c3f1149bffcde1dec98dea88a442e2b580d750a";
          hash = "sha256-qyfeyR3Yp5i1YROqaOp4QP8U0rYCXgdeeUKbbXQJMU4=";
        };
      }
    ];

    nativeBuildInputs = [ pkgs.zig_0_14 ];

    zigBuildFlags = [
      "-Doptimize=ReleaseFast"
      "--system"
      "${finalAttrs.deps}"
    ];

    meta = {
      description = "AcoustID fingerprint search engine";
      homepage = "https://github.com/acoustid/acoustid-index";
      license = pkgs.lib.licenses.gpl3;
      platforms = pkgs.lib.platforms.linux;
      mainProgram = "acoustid-index";
    };
  });

  # ---------------------------------------------------------------------------
  # AcoustID URL generator for aria2c bulk download
  # ---------------------------------------------------------------------------
  acoustidUrlGenerator = pkgs.writeText "acoustid-urls.py" ''
    import sys
    from datetime import datetime, timedelta

    start_date = datetime.strptime(sys.argv[1], "%Y-%m-%d")
    end_date = datetime.strptime(sys.argv[2], "%Y-%m-%d")
    base_url = "https://data.acoustid.org"

    current = start_date
    while current <= end_date:
        year, month = current.strftime("%Y"), current.strftime("%Y-%m")
        date_str = current.strftime("%Y-%m-%d")

        for file_type in ["fingerprint", "track", "track_mbid"]:
            url = "{}/{}/{}/{}-{}-update.jsonl.gz".format(
                base_url, year, month, date_str, file_type
            )
            print(url)

        current += timedelta(days=1)
  '';

  # ---------------------------------------------------------------------------
  # AcoustID data import Python script
  # ---------------------------------------------------------------------------
  acoustidImportPython = pkgs.writeText "acoustid-import.py" ''
    import sys, gzip, json, psycopg2
    from datetime import datetime, timedelta
    from pathlib import Path
    from io import StringIO

    conn = psycopg2.connect("dbname=acoustid user=postgres")
    cur = conn.cursor()

    conn.set_session(autocommit=False)
    cur.execute("SET synchronous_commit = OFF")
    cur.execute("SET maintenance_work_mem = '2GB'")
    cur.execute("SET session_replication_role = 'replica'")

    def bulk_import_tracks(filepath):
        print("  Importing tracks...")
        buffer = StringIO()
        count = 0

        with gzip.open(filepath, 'rt') as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    data = json.loads(line)
                    gid = data.get('gid') or ""
                    buffer.write("{}\\t{}\\n".format(data['id'], gid))
                    count += 1

                    if count % 50000 == 0:
                        buffer.seek(0)
                        cur.copy_expert(
                            "COPY track (id, gid) FROM STDIN WITH (FORMAT text)",
                            buffer
                        )
                        conn.commit()
                        buffer = StringIO()
                        print("    {:,} records...".format(count), end="\r", flush=True)
                except Exception as e:
                    print("\n    Error: {}".format(e))
                    continue

        if buffer.tell() > 0:
            buffer.seek(0)
            cur.copy_expert(
                "COPY track (id, gid) FROM STDIN WITH (FORMAT text)",
                buffer
            )
            conn.commit()

        print("    {:,} records total".format(count))
        return count

    def bulk_import_track_mbids(filepath):
        print("  Importing track→MBID mappings...")
        buffer = StringIO()
        count = 0

        with gzip.open(filepath, 'rt') as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    data = json.loads(line)
                    if data.get('disabled'):
                        continue

                    buffer.write("{}\\t{}\\t{}\\t{}\\n".format(
                        data['id'],
                        data['track_id'],
                        data['mbid'],
                        data.get('submission_count', 0)
                    ))
                    count += 1

                    if count % 50000 == 0:
                        buffer.seek(0)
                        cur.copy_expert(
                            "COPY track_mbid (id, track_id, mbid, submission_count) "
                            "FROM STDIN WITH (FORMAT text)",
                            buffer
                        )
                        conn.commit()
                        buffer = StringIO()
                        print("    {:,} records...".format(count), end="\r", flush=True)
                except Exception as e:
                    print("\n    Error: {}".format(e))
                    continue

        if buffer.tell() > 0:
            buffer.seek(0)
            cur.copy_expert(
                "COPY track_mbid (id, track_id, mbid, submission_count) "
                "FROM STDIN WITH (FORMAT text)",
                buffer
            )
            conn.commit()

        print("    {:,} records total".format(count))
        return count

    def bulk_import_fingerprints(filepath, index_dir):
        print("  Processing fingerprints...")
        fp_file = "{}/fingerprints.jsonl".format(index_dir)
        count = 0

        with gzip.open(filepath, 'rt') as f_in, open(fp_file, 'a') as f_out:
            for line in f_in:
                if not line.strip():
                    continue
                try:
                    data = json.loads(line)
                    f_out.write(json.dumps({
                        "insert": {
                            "id": data['id'],
                            "hashes": data['fingerprint'][:120]
                        }
                    }) + '\n')
                    count += 1

                    if count % 50000 == 0:
                        print("    {:,} records...".format(count), end="\r", flush=True)
                except Exception as e:
                    print("\n    Error: {}".format(e))
                    continue

        print("    {:,} records total".format(count))
        return count

    data_dir = Path(sys.argv[1])
    index_dir = sys.argv[2]
    start_date = datetime.strptime(sys.argv[3], "%Y-%m-%d")
    end_date = datetime.strptime(sys.argv[4], "%Y-%m-%d")
    current_date = start_date

    total_days = (end_date - start_date).days + 1
    day_num = 0

    total_tracks = 0
    total_mbids = 0
    total_fps = 0

    while current_date <= end_date:
        day_num += 1
        date_str = current_date.strftime("%Y-%m-%d")
        print("\n[{}/{}] Processing {}".format(day_num, total_days, date_str))

        track_file = data_dir / "{}-track-update.jsonl.gz".format(date_str)
        if track_file.exists():
            total_tracks += bulk_import_tracks(track_file)

        mbid_file = data_dir / "{}-track_mbid-update.jsonl.gz".format(date_str)
        if mbid_file.exists():
            total_mbids += bulk_import_track_mbids(mbid_file)

        fp_file = data_dir / "{}-fingerprint-update.jsonl.gz".format(date_str)
        if fp_file.exists():
            total_fps += bulk_import_fingerprints(fp_file, index_dir)

        current_date += timedelta(days=1)

    print("\nRestoring constraints...")
    cur.execute("SET session_replication_role = 'origin'")
    cur.execute("ANALYZE")
    conn.commit()

    cur.close()
    conn.close()

    print("\n" + "="*50)
    print("✓ Import complete!")
    print("="*50)
    print("Total tracks: {:,}".format(total_tracks))
    print("Total track→MBID mappings: {:,}".format(total_mbids))
    print("Total fingerprints: {:,}".format(total_fps))
  '';

  # ---------------------------------------------------------------------------
  # AcoustID import script
  # ---------------------------------------------------------------------------
  acoustidImportScript = let
    psql = "${config.services.postgresql.package}/bin/psql";
    python = "${pkgs.python3}/bin/python3";
    aria2c = "${pkgs.aria2}/bin/aria2c";
  in pkgs.writeShellScript "acoustid-import" ''
    set -euo pipefail

    START_DATE=''${ACOUSTID_START_DATE:-"2011-08-01"}
    END_DATE=''${ACOUSTID_END_DATE:-$(date +%Y-%m-%d)}
    DATA_DIR=/mnt/deepstor/acoustid-data
    INDEX_DIR=/mnt/deepstor/acoustid-index

    echo "AcoustID Database Import"
    echo "========================"
    echo "Date range: $START_DATE to $END_DATE"
    echo

    mkdir -p "$DATA_DIR" "$INDEX_DIR"

    echo "Generating download URLs..."
    ${python} ${acoustidUrlGenerator} "$START_DATE" "$END_DATE" > "$DATA_DIR/urls.txt"
    URL_COUNT=$(wc -l < "$DATA_DIR/urls.txt")
    echo "Generated $URL_COUNT URLs"
    echo

    echo "Downloading dumps with aria2c..."
    ${aria2c} \
      --input-file="$DATA_DIR/urls.txt" \
      --dir="$DATA_DIR" \
      --max-connection-per-server=2 \
      --max-concurrent-downloads=4 \
      --min-split-size=10M \
      --max-overall-download-limit=50M \
      --continue=true \
      --auto-file-renaming=false \
      --allow-overwrite=false \
      --summary-interval=10

    echo
    echo "Importing data into PostgreSQL..."
    ${python} ${acoustidImportPython} "$DATA_DIR" "$INDEX_DIR" "$START_DATE" "$END_DATE"

    echo
    echo "Database statistics:"
    ${psql} -d acoustid -c "
      SELECT 'Tracks' as type, COUNT(*)::text as count FROM track
      UNION ALL SELECT 'Track→MBID mappings', COUNT(*)::text FROM track_mbid;
    "

    if [ -f "$INDEX_DIR/fingerprints.jsonl" ]; then
      echo
      echo "Loading fingerprints into acoustid-index..."
      ${pkgs.curl}/bin/curl -X POST \
        -H "Content-Type: application/x-ndjson" \
        --data-binary @"$INDEX_DIR/fingerprints.jsonl" \
        http://localhost:8081/acoustid/_update
      echo "✓ Fingerprint index updated"
      rm "$INDEX_DIR/fingerprints.jsonl"
    fi

    echo
    echo "✓ AcoustID database ready!"
  '';
in
{
  # ---------------------------------------------------------------------------
  # PostgreSQL - shared by MusicBrainz + AcoustID
  # ---------------------------------------------------------------------------
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    dataDir = "/mnt/md0/postgresql";
    enableTCPIP = true;

    authentication = lib.mkAfter ''
      host musicbrainz musicbrainz 172.16.0.0/12 scram-sha-256
      host musicbrainz musicbrainz 0.0.0.0/0 scram-sha-256
      host acoustid acoustid 0.0.0.0/0 scram-sha-256
    '';

    ensureDatabases = [ "musicbrainz" "acoustid" ];
    ensureUsers = [
      {
        name = "musicbrainz";
        ensureDBOwnership = true;
      }
      {
        name = "acoustid";
        ensureDBOwnership = true;
      }
    ];

    settings = {
      shared_buffers = "2GB";
      effective_cache_size = "6GB";
      work_mem = "256MB";
      maintenance_work_mem = "512MB";
      listen_addresses = "*";
    };
  };

  systemd.services.postgresql = {
    after = [ "mnt-md0.mount" ];
    requires = [ "mnt-md0.mount" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/md0/postgresql 0700 postgres postgres -"
    "d /mnt/deepstor/acoustid-index 0755 acoustid acoustid -"
    "d /mnt/deepstor/acoustid-data 0755 postgres postgres -"
    "d ${musicbrainzDockerRoot} 0755 root root -"
  ];

  # ---------------------------------------------------------------------------
  # MusicBrainz database setup
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
          set -euo pipefail

          ${psql} -d musicbrainz -c "CREATE EXTENSION IF NOT EXISTS cube;"
          ${psql} -d musicbrainz -c "CREATE EXTENSION IF NOT EXISTS earthdistance;"

          DB_PASSWORD=$(cat ${config.sops.secrets."musicbrainz/db-password".path} | sed "s/'/'''/g")
          ${psql} -d musicbrainz <<EOF
ALTER USER musicbrainz PASSWORD '$DB_PASSWORD';
EOF
        '';
    };
  };

  # ---------------------------------------------------------------------------
  # MusicBrainz Docker setup
  # ---------------------------------------------------------------------------
  virtualisation.docker.enable = true;

  systemd.services.musicbrainz-docker-setup = {
    description = "Setup MusicBrainz Docker repository";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "docker.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mb-docker-setup" ''
        set -e
        NEEDS_BUILD=false
        if [ ! -d "${musicbrainzDockerRoot}/.git" ]; then
          ${pkgs.git}/bin/git clone https://github.com/metabrainz/musicbrainz-docker.git ${musicbrainzDockerRoot}
          NEEDS_BUILD=true
        fi

        cd ${musicbrainzDockerRoot}

        # Get host IP for Docker containers to reach host PostgreSQL
        HOST_IP=$(${pkgs.iproute2}/bin/ip -4 addr show docker0 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "172.17.0.1")

        # Read DB password from sops
        DB_PASSWORD=$(cat ${config.sops.secrets."musicbrainz/db-password".path})

        # Compose override to route musicbrainz container to host PostgreSQL
        ${pkgs.coreutils}/bin/cat > docker-compose.host-db.yml <<EOF
services:
  musicbrainz:
    environment:
      - MUSICBRAINZ_POSTGRES_SERVER=$HOST_IP
      - MUSICBRAINZ_POSTGRES_READONLY_SERVER=$HOST_IP
      - POSTGRES_PASSWORD=$DB_PASSWORD
EOF

        ${pkgs.coreutils}/bin/cat > .env <<EOF
# Database-only mirror mode with host PostgreSQL
COMPOSE_FILE=docker-compose.yml:docker-compose.alt.db-only-mirror.yml:docker-compose.host-db.yml
EOF

        mkdir -p local/secrets
        cp ${config.sops.secrets."musicbrainz/replication-token".path} local/secrets/metabrainz_access_token

        if [ "$NEEDS_BUILD" = "true" ]; then
          ${pkgs.docker}/bin/docker compose build
        fi
      '';
    };
  };

  # Hourly replication
  systemd.services.musicbrainz-docker-replication = {
    description = "MusicBrainz Docker replication sync";
    after = [ "postgresql.service" "musicbrainz-db-setup.service" "docker.service" "musicbrainz-docker-setup.service" ];
    requires = [ "postgresql.service" "docker.service" "musicbrainz-docker-setup.service" ];

    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = musicbrainzDockerRoot;
      ExecStart = pkgs.writeShellScript "mb-docker-replication" ''
        set -e
        cd ${musicbrainzDockerRoot}
        ${pkgs.docker}/bin/docker compose run --rm musicbrainz replication.sh
      '';
    };
  };

  systemd.timers.musicbrainz-docker-replication = {
    description = "MusicBrainz hourly replication";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  # ---------------------------------------------------------------------------
  # AcoustID database setup
  # ---------------------------------------------------------------------------
  systemd.services.acoustid-db-setup = {
    description = "AcoustID PostgreSQL schema setup";
    after = [ "postgresql.service" "postgresql-setup.service" ];
    requires = [ "postgresql.service" "postgresql-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      ExecStart = let psql = "${config.services.postgresql.package}/bin/psql"; in
        pkgs.writeShellScript "acoustid-db-setup" ''
          set -euo pipefail

          ${psql} -d acoustid << 'EOF'
CREATE TABLE IF NOT EXISTS track (
    id INTEGER PRIMARY KEY,
    gid UUID
);
CREATE INDEX IF NOT EXISTS track_gid_idx ON track(gid);

CREATE TABLE IF NOT EXISTS track_mbid (
    id INTEGER PRIMARY KEY,
    track_id INTEGER REFERENCES track(id),
    mbid UUID NOT NULL,
    submission_count INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS track_mbid_track_idx ON track_mbid(track_id);
CREATE INDEX IF NOT EXISTS track_mbid_mbid_idx ON track_mbid(mbid);

CREATE OR REPLACE VIEW track_mbid_summary AS
SELECT
    track_id,
    mbid,
    submission_count
FROM track_mbid
WHERE NOT EXISTS (
    SELECT 1 FROM track_mbid tm2
    WHERE tm2.track_id = track_mbid.track_id
    AND tm2.submission_count > track_mbid.submission_count
)
ORDER BY submission_count DESC;
EOF

          echo "✓ AcoustID schema created"
        '';
    };
  };

  # ---------------------------------------------------------------------------
  # acoustid-index service
  # ---------------------------------------------------------------------------
  systemd.services.acoustid-index = {
    description = "AcoustID fingerprint search engine";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "acoustid";
      Group = "acoustid";
      ExecStart = "${acoustid-index}/bin/fpindex --dir /mnt/deepstor/acoustid-index --host 0.0.0.0 --port 8081";
      Restart = "always";
      RestartSec = "10s";
    };
  };

  users.users.acoustid = {
    isSystemUser = true;
    group = "acoustid";
    description = "AcoustID service user";
  };
  users.groups.acoustid = {};

  # ---------------------------------------------------------------------------
  # AcoustID import services
  # ---------------------------------------------------------------------------
  systemd.services.acoustid-init = {
    description = "AcoustID initial data import";
    after = [ "postgresql.service" "acoustid-db-setup.service" "acoustid-index.service" ];
    requires = [ "postgresql.service" "acoustid-db-setup.service" "acoustid-index.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      StandardOutput = "journal";
      StandardError = "journal";
      TimeoutStartSec = "infinity";
      ExecStart = acoustidImportScript;
    };
  };

  systemd.services.acoustid-sync = {
    description = "AcoustID daily sync";
    after = [ "postgresql.service" "acoustid-index.service" ];
    requires = [ "postgresql.service" "acoustid-index.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Environment = [
        "ACOUSTID_START_DATE=$(date -d yesterday +%Y-%m-%d)"
        "ACOUSTID_END_DATE=$(date +%Y-%m-%d)"
      ];
      ExecStart = acoustidImportScript;
    };
  };

  systemd.timers.acoustid-sync = {
    description = "AcoustID daily sync";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # ---------------------------------------------------------------------------
  # Secrets
  # ---------------------------------------------------------------------------
  sops.secrets."musicbrainz/replication-token" = {
    owner = "root";
    mode = "0400";
  };
  sops.secrets."musicbrainz/db-password" = {
    owner = "postgres";
    mode = "0400";
  };
  sops.secrets."acoustid/db-password" = {
    owner = "postgres";
    mode = "0400";
  };

  # ---------------------------------------------------------------------------
  # Firewall & packages
  # ---------------------------------------------------------------------------
  networking.firewall.allowedTCPPorts = [
    5432  # PostgreSQL
    8081  # acoustid-index
  ];

  environment.systemPackages = [
    acoustid-index
    pkgs.chromaprint
    pkgs.aria2
    pkgs.docker-compose
  ];
}
