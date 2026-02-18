# MusicBrainz + AcoustID Audio Fingerprinting Server
# 
# COMPONENTS:
#   - MusicBrainz: PostgreSQL database with music metadata (~45 GB)
#   - AcoustID: Audio fingerprint → MusicBrainz ID matching (~35 GB)
#   - acoustid-index: Fast fingerprint search engine (HTTP API on :8081)
#
# INITIAL SETUP:
#   1. MusicBrainz database:
#      $ sudo systemctl start musicbrainz-init
#      $ journalctl -u musicbrainz-init -f  # Monitor (2-6 hours)
#
#   2. AcoustID fingerprint database:
#      # Full backfill (2011-2026, ~200 GB download):
#      $ ACOUSTID_START_DATE=2011-08-01 sudo systemctl start acoustid-init
#      
#      # Recent data only (faster, for testing):
#      $ ACOUSTID_START_DATE=2024-01-01 sudo systemctl start acoustid-init
#      
#      $ journalctl -u acoustid-init -f  # Monitor progress
#
# PERFORMANCE OPTIMIZATIONS:
#   - session_replication_role='replica': Disables ALL constraints/triggers
#     during import for massive speedup (standard PostgreSQL bulk load)
#   - aria2c: 16 connections/file, 20 parallel downloads
#   - PostgreSQL COPY: ~10x faster than individual INSERTs
#   - Constraints/triggers automatically restored after import
#   - Full backfill: ~6-12 hours (network/CPU dependent)
#
# DATA QUALITY:
#   - MusicBrainz dumps may contain minor data issues (empty strings, etc.)
#   - session_replication_role bypasses constraints during import
#   - ANALYZE run after import to rebuild query optimizer statistics
#
# ONGOING MAINTENANCE:
#   - MusicBrainz sync: hourly (musicbrainz-sync.timer)
#   - AcoustID sync: daily (acoustid-sync.timer)
#
# ACOUSTID LOOKUP API:
#   POST http://localhost:8081/acoustid/_search
#   {"query": [fingerprint_hashes], "limit": 10}
{ config, pkgs, lib, ... }:

let
  # ---------------------------------------------------------------------------
  # acoustid-index: Fast fingerprint search engine (Zig)
  # ---------------------------------------------------------------------------
  acoustid-index = pkgs.stdenv.mkDerivation rec {
    pname = "acoustid-index";
    version = "2025-10-27";
    
    src = pkgs.fetchFromGitHub {
      owner = "acoustid";
      repo = "acoustid-index";
      rev = "6bc929a316e4f3a9c9ec37a395f30e0f5b7116c2";
      hash = "sha256-hqWsbQEEs02p3UOuR5zptKE60GxSPvVoysrrtXx7nyc=";
    };
    
    nativeBuildInputs = [ pkgs.zig_0_13 ];
    
    buildPhase = ''
      zig build -Doptimize=ReleaseFast
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      cp zig-out/bin/acoustid-index $out/bin/
    '';
    
    meta = {
      description = "AcoustID fingerprint search engine";
      homepage = "https://github.com/acoustid/acoustid-index";
      license = pkgs.lib.licenses.gpl3;
    };
  };

  # ---------------------------------------------------------------------------
  # MusicBrainz replication tool
  # ---------------------------------------------------------------------------
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

  musicbrainzInitScript = let
    psql = "${config.services.postgresql.package}/bin/psql";
    mbslaveBin = "${mbslave}/bin/mbslave";
    curl = "${pkgs.curl}/bin/curl";
    sha256sum = "${pkgs.coreutils}/bin/sha256sum";
  in pkgs.writeShellScript "musicbrainz-init" ''
    set -euo pipefail
    
    export MBSLAVE_CONFIG=${mbslaveConfig}
    export MBSLAVE_MUSICBRAINZ_TOKEN=$(cat ${config.sops.secrets."musicbrainz/replication-token".path})
    
    DUMP_DIR=/mnt/deepstor/musicbrainz-dumps
    BASE_URL=https://data.metabrainz.org/pub/musicbrainz/data/fullexport
    
    echo "MusicBrainz Initial Database Setup"
    echo "==================================="
    echo
    
    # Check if database already populated
    TABLE_COUNT=$(${psql} -d musicbrainz -tAc "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'musicbrainz';" || echo 0)
    if [ "$TABLE_COUNT" -gt 100 ]; then
      echo "✗ Database already has $TABLE_COUNT tables"
      echo
      echo "To re-import, first run:"
      echo "  sudo -u postgres psql -c 'DROP DATABASE musicbrainz;'"
      echo "  sudo -u postgres psql -c 'CREATE DATABASE musicbrainz OWNER musicbrainz;'"
      echo "  sudo systemctl restart musicbrainz-db-setup"
      echo "  sudo systemctl start musicbrainz-init"
      exit 1
    fi
    
    # Create dump directory
    mkdir -p "$DUMP_DIR"
    cd "$DUMP_DIR"
    
    # Get latest version
    echo "Fetching latest dump version..."
    LATEST=$(${curl} -sf "$BASE_URL/LATEST" | tr -d '\n')
    echo "Latest: $LATEST"
    echo
    
    DUMP_URL="$BASE_URL/$LATEST"
    
    # Required dumps
    declare -a DUMPS=(
      "mbdump.tar.bz2"
      "mbdump-derived.tar.bz2"
      "mbdump-editor.tar.bz2"
      "mbdump-cover-art-archive.tar.bz2"
    )
    
    # Download with resume support
    echo "Downloading dumps (~6.7 GB)..."
    for dump in "''${DUMPS[@]}"; do
      if [ -f "$dump" ]; then
        echo "  $dump (resuming existing)"
      else
        echo "  $dump"
      fi
      ${curl} -# -L -C - -o "$dump" "$DUMP_URL/$dump"
    done
    
    # Download and verify checksums
    echo
    echo "Verifying downloads..."
    ${curl} -sf -L -o SHA256SUMS "$DUMP_URL/SHA256SUMS"
    
    VERIFY_OUTPUT=$(${sha256sum} -c SHA256SUMS 2>&1 | grep -E "$(echo "''${DUMPS[@]}" | tr ' ' '|')" || true)
    if echo "$VERIFY_OUTPUT" | grep -q "FAILED"; then
      echo "✗ Checksum verification failed"
      echo "$VERIFY_OUTPUT"
      exit 1
    fi
    echo "✓ Checksums verified"
    echo
    
    # Create schema
    echo "Creating database schema..."
    ${mbslaveBin} init --empty
    echo "✓ Schema created"
    echo
    
    # Enable replica mode for faster imports (disables constraints/triggers)
    echo "Enabling fast import mode (disables constraints during import)..."
    ${psql} -d musicbrainz -c "SET session_replication_role = 'replica';"
    echo
    
    # Import data
    echo "Importing data (2-6 hours)..."
    echo "NOTE: Constraints/triggers disabled for performance"
    echo
    
    echo "[1/4] Core data (1-4 hours)..."
    ${mbslaveBin} import mbdump.tar.bz2
    
    echo "[2/4] Editor data..."
    ${mbslaveBin} import mbdump-editor.tar.bz2
    
    echo "[3/4] Derived data..."
    ${mbslaveBin} import mbdump-derived.tar.bz2
    
    echo "[4/4] Cover art..."
    ${mbslaveBin} import mbdump-cover-art-archive.tar.bz2
    
    echo
    echo "✓ Data import complete"
    echo
    
    # Restore normal mode
    echo "Restoring constraints..."
    ${psql} -d musicbrainz -c "SET session_replication_role = 'origin';"
    ${psql} -d musicbrainz -c "ANALYZE;"
    echo "✓ Constraints restored"
    echo
    
    # Show statistics
    ${psql} -d musicbrainz -c "
      SELECT pg_size_pretty(pg_database_size('musicbrainz')) as \"Database Size\";
    "
    ${psql} -d musicbrainz -c "
      SELECT 'Artists' as \"Type\", COUNT(*)::text as \"Count\" FROM musicbrainz.artist
      UNION ALL SELECT 'Releases', COUNT(*)::text FROM musicbrainz.release
      UNION ALL SELECT 'Recordings', COUNT(*)::text FROM musicbrainz.recording;
    "
    
    # Cleanup
    echo
    echo "Cleaning up dumps..."
    rm -f mbdump*.tar.bz2 SHA256SUMS
    echo "✓ Freed 6.7 GB"
    echo
    echo "Hourly sync (musicbrainz-sync.timer) will keep database updated."
  '';

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
        
        # Only essential files (skip track_fingerprint, track_meta, meta, track_puid)
        for file_type in ["fingerprint", "track", "track_mbid"]:
            url = "{}/{}/{}/{}-{}-update.jsonl.gz".format(
                base_url, year, month, date_str, file_type
            )
            print(url)
        
        current += timedelta(days=1)
  '';

  # ---------------------------------------------------------------------------
  # AcoustID data import Python script (optimized with COPY)
  # ---------------------------------------------------------------------------
  acoustidImportPython = pkgs.writeText "acoustid-import.py" ''
    import sys, gzip, json, psycopg2
    from datetime import datetime, timedelta
    from pathlib import Path
    from io import StringIO

    conn = psycopg2.connect("dbname=acoustid user=postgres")
    cur = conn.cursor()

    # Optimize for bulk import
    conn.set_session(autocommit=False)
    cur.execute("SET synchronous_commit = OFF")
    cur.execute("SET maintenance_work_mem = '2GB'")
    cur.execute("SET session_replication_role = 'replica'")  # Disable constraints/triggers

    def bulk_import_tracks(filepath):
        """Bulk import tracks using COPY"""
        print("  Importing tracks...")
        buffer = StringIO()
        count = 0
        
        with gzip.open(filepath, 'rt') as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    data = json.loads(line)
                    # Format: id\tgid
                    gid = data.get('gid')
                    if not gid:
                        gid = ""
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
        
        # Final batch
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
        """Bulk import track→MBID mappings using COPY"""
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
                        continue  # Skip disabled
                    
                    # Format: id\ttrack_id\tmbid\tsubmission_count
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
        
        # Final batch
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
        """Stream fingerprints to acoustid-index JSONL"""
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

    # Main import loop
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
        
        # Import tracks
        track_file = data_dir / "{}-track-update.jsonl.gz".format(date_str)
        if track_file.exists():
            total_tracks += bulk_import_tracks(track_file)
        
        # Import track→MBID mappings
        mbid_file = data_dir / "{}-track_mbid-update.jsonl.gz".format(date_str)
        if mbid_file.exists():
            total_mbids += bulk_import_track_mbids(mbid_file)
        
        # Import fingerprints
        fp_file = data_dir / "{}-fingerprint-update.jsonl.gz".format(date_str)
        if fp_file.exists():
            total_fps += bulk_import_fingerprints(fp_file, index_dir)
        
        current_date += timedelta(days=1)

    # Restore normal mode and cleanup
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
  # AcoustID data import shell wrapper
  # ---------------------------------------------------------------------------
  acoustidImportScript = let
    psql = "${config.services.postgresql.package}/bin/psql";
    python = "${pkgs.python3}/bin/python3";
    aria2c = "${pkgs.aria2}/bin/aria2c";
  in pkgs.writeShellScript "acoustid-import" ''
    set -euo pipefail
    
    # Configuration
    START_DATE=''${ACOUSTID_START_DATE:-"2024-01-01"}
    END_DATE=''${ACOUSTID_END_DATE:-$(date +%Y-%m-%d)}
    DATA_DIR=/mnt/deepstor/acoustid-data
    INDEX_DIR=/mnt/deepstor/acoustid-index
    
    echo "AcoustID Database Import"
    echo "========================"
    echo "Date range: $START_DATE to $END_DATE"
    echo "Data dir: $DATA_DIR"
    echo "Index dir: $INDEX_DIR"
    echo
    
    # Create directories
    mkdir -p "$DATA_DIR" "$INDEX_DIR"
    
    # Check if database already has data
    TRACK_COUNT=$(${psql} -d acoustid -tAc "SELECT COUNT(*) FROM track;" || echo 0)
    if [ "$TRACK_COUNT" -gt 0 ]; then
      echo "⚠ Database already has $TRACK_COUNT tracks"
      echo "This will append new data. To start fresh, first run:"
      echo "  sudo -u postgres psql -c 'DROP DATABASE acoustid;'"
      echo "  sudo -u postgres psql -c 'CREATE DATABASE acoustid;'"
      echo "  sudo systemctl restart acoustid-db-setup"
      echo
      read -p "Continue anyway? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
      fi
    fi
    
    # Generate URL list
    echo "Generating download URLs..."
    ${python} ${acoustidUrlGenerator} "$START_DATE" "$END_DATE" > "$DATA_DIR/urls.txt"
    URL_COUNT=$(wc -l < "$DATA_DIR/urls.txt")
    echo "Generated $URL_COUNT URLs"
    echo
    
    # Download with aria2c (parallel, resumable)
    echo "Downloading dumps with aria2c (parallel)..."
    echo "This may take 1-2 hours depending on bandwidth..."
    ${aria2c} \
      --input-file="$DATA_DIR/urls.txt" \
      --dir="$DATA_DIR" \
      --max-connection-per-server=16 \
      --max-concurrent-downloads=20 \
      --min-split-size=1M \
      --continue=true \
      --auto-file-renaming=false \
      --allow-overwrite=false \
      --summary-interval=10
    
    echo
    echo "✓ Download complete"
    echo
    
    # Import data
    echo "Importing data into PostgreSQL..."
    ${python} ${acoustidImportPython} "$DATA_DIR" "$INDEX_DIR" "$START_DATE" "$END_DATE"
    
    # Show statistics
    echo
    echo "Database statistics:"
    ${psql} -d acoustid -c "
      SELECT 'Tracks' as type, COUNT(*)::text as count FROM track
      UNION ALL SELECT 'Track→MBID mappings', COUNT(*)::text FROM track_mbid;
    "
    
    # Load fingerprints into acoustid-index
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
    echo "Daily updates will sync automatically via acoustid-sync.timer"
  '';
in
{
  # ---------------------------------------------------------------------------
  # PostgreSQL - data on RAID array (shared by MusicBrainz + AcoustID)
  # ---------------------------------------------------------------------------
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    dataDir = "/mnt/md0/postgresql";
    enableTCPIP = true;

    # Allow remote clients to connect
    authentication = lib.mkAfter ''
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
    };
  };

  # PostgreSQL must wait for RAID mount
  systemd.services.postgresql = {
    after = [ "mnt-md0.mount" ];
    requires = [ "mnt-md0.mount" ];
  };

  # Ensure data directories exist with correct ownership
  systemd.tmpfiles.rules = [
    "d /mnt/md0/postgresql 0700 postgres postgres -"
    "d /mnt/deepstor/acoustid-index 0755 acoustid acoustid -"
    "d /mnt/deepstor/acoustid-data 0755 postgres postgres -"
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
          set -euo pipefail
          
          # Create extensions
          ${psql} -d musicbrainz -c "CREATE EXTENSION IF NOT EXISTS cube;"
          ${psql} -d musicbrainz -c "CREATE EXTENSION IF NOT EXISTS earthdistance;"
          
          # Set password securely (escape single quotes)
          DB_PASSWORD=$(cat ${config.sops.secrets."musicbrainz/db-password".path} | sed "s/'/'''/g")
          ${psql} -d musicbrainz <<EOF
ALTER USER musicbrainz PASSWORD '$DB_PASSWORD';
EOF
        '';
    };
  };

  # ---------------------------------------------------------------------------
  # AcoustID database setup
  # ---------------------------------------------------------------------------
  systemd.services.acoustid-db-setup = {
    description = "AcoustID PostgreSQL database schema setup";
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
          
          # Create schema
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

-- View for easy lookups
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
  # acoustid-index service (fingerprint search engine)
  # ---------------------------------------------------------------------------
  systemd.services.acoustid-index = {
    description = "AcoustID fingerprint search engine";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = "acoustid";
      Group = "acoustid";
      ExecStart = "${acoustid-index}/bin/acoustid-index --dir /mnt/deepstor/acoustid-index --host 0.0.0.0 --port 8081";
      Restart = "always";
      RestartSec = "10s";
    };
  };

  # Create acoustid user
  users.users.acoustid = {
    isSystemUser = true;
    group = "acoustid";
    description = "AcoustID service user";
  };
  users.groups.acoustid = {};

  # ---------------------------------------------------------------------------
  # AcoustID initial data import
  # Usage: ACOUSTID_START_DATE=2024-01-01 sudo systemctl start acoustid-init
  # ---------------------------------------------------------------------------
  systemd.services.acoustid-init = {
    description = "AcoustID initial data import";
    after = [ "postgresql.service" "acoustid-db-setup.service" "acoustid-index.service" ];
    requires = [ "postgresql.service" "acoustid-db-setup.service" "acoustid-index.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      TimeoutStartSec = "infinity";
      ExecStart = acoustidImportScript;
    };
  };

  # ---------------------------------------------------------------------------
  # AcoustID daily sync
  # ---------------------------------------------------------------------------
  systemd.services.acoustid-sync = {
    description = "AcoustID daily data sync";
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
  # Initial database setup - download dumps + import
  # Usage: sudo systemctl start musicbrainz-init
  # ---------------------------------------------------------------------------
  systemd.services.musicbrainz-init = {
    description = "MusicBrainz initial database setup (download + import)";
    after = [ "postgresql.service" "musicbrainz-db-setup.service" ];
    requires = [ "postgresql.service" "musicbrainz-db-setup.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      TimeoutStartSec = "infinity";
      ExecStart = musicbrainzInitScript;
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
  sops.secrets."acoustid/db-password" = {
    owner = "postgres";
    mode = "0400";
  };

  # ---------------------------------------------------------------------------
  # Firewall & packages
  # ---------------------------------------------------------------------------
  networking.firewall.allowedTCPPorts = [ 
    5432  # PostgreSQL (MusicBrainz + AcoustID)
    8081  # acoustid-index HTTP API
  ];
  
  environment.systemPackages = [ 
    mbslave
    acoustid-index
    pkgs.chromaprint  # fpcalc for generating fingerprints
    pkgs.aria2        # Parallel downloads for AcoustID data
  ];
}
