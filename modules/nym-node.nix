# Nym mixnet node
#
# The node is stateful by design: it generates its own keys and rewrites its
# config.toml, and that config bakes absolute paths derived from $HOME. So
# $HOME must be a stable location (StateDirectory), and the node must be
# addressed by `--id` rather than a config path. Declarative settings are
# passed as NYMNODE_* environment variables and folded into config.toml on
# every start via `--write-changes`.
#
# Identity
# --------
# The ed25519 identity key is what the mixnet contract bonds to, so it has to
# outlive the disk. Generate one anywhere with a network connection (the
# placeholder address below only shapes a config that is thrown away):
#
#   env HOME=/tmp/nymgen NYMNODE_ID=k NYMNODE_MODE=mixnode NYMNODE_PUBLIC_IPS=1.2.3.4 \
#     nix shell nixpkgs#nym -c nym-node run --init-only -w --accept-operator-terms-and-conditions
#   env HOME=/tmp/nymgen nix shell nixpkgs#nym -c nym-node bonding-information --id k
#   base64 -w64 /tmp/nymgen/.nym/nym-nodes/k/data/ed25519_identity      # -> identityKeyFile
#   base64 -w64 /tmp/nymgen/.nym/nym-nodes/k/data/ed25519_identity.pub  # -> identityPublicKeyFile
#   rm -rf /tmp/nymgen
#
#  CRITICAL: Store the identityKeyFile and identityPublicKeyFile in a secret store
#
# the keys for the nym node are overwritten by these identityKeyFile and identityPublicKeyFile options
#
# Everything not exposed below is left at the binary's own defaults, which are
# correct as shipped — including the nym-api and nyxd URLs and the bind ports.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.nym-node;
  stateDir = "/var/lib/nym-node";
  nodeDir = "${stateDir}/.nym/nym-nodes/${cfg.id}";

  # nym-node's own default; referenced by the firewall and the IP-sync check.
  httpPort = 8080;

  # nym-node has no built-in public-IP detection and refuses to start with no
  # announced address, despite its config template implying the nym-api
  # backfills it; upstream's own docs resolve it with curl. Several providers
  # are tried so one being down does not take the node with it.
  resolveIp = pkgs.writeShellScript "nym-node-resolve-ip" ''
    set -euo pipefail
    for url in https://api.ipify.org https://ifconfig.me https://icanhazip.com; do
      ip=$(${pkgs.curl}/bin/curl -4 -sf --max-time 10 "$url" | tr -d '[:space:]') || continue
      case "$ip" in
        [0-9]*.[0-9]*.[0-9]*.[0-9]*) printf '%s' "$ip"; exit 0 ;;
      esac
    done
    exit 1
  '';

  # Both the init pre-step and the run itself need an announced address.
  announceIps = lib.optionalString (cfg.publicIps == [ ]) ''
    if ! NYMNODE_PUBLIC_IPS=$(${resolveIp}); then
      echo "nym-node: could not resolve a public IPv4 address; set services.nym-node.publicIps to override" >&2
      exit 1
    fi
    export NYMNODE_PUBLIC_IPS
  '';

  # Key material is stored base64-encoded rather than as raw PEM: nym-node
  # writes its PEM with CRLF line endings, which YAML block scalars silently
  # normalise to LF, corrupting the key on the way back out.
  seed = pkgs.writeShellScript "nym-node-seed" ''
    set -euo pipefail
    ${announceIps}

    # Upstream ships no `init` subcommand; this is it. Idempotent once
    # config.toml exists, so it is safe to run on every start.
    ${cfg.package}/bin/nym-node --no-banner run --init-only --write-changes \
      --accept-operator-terms-and-conditions

    ${lib.optionalString (cfg.identityKeyFile != null) ''
      # The secret store is authoritative: on a fresh host the init above just
      # minted a throwaway identity, and this replaces it with the bonded one.
      install -d -m 0700 "${nodeDir}/data"

      ( umask 077
        ${pkgs.coreutils}/bin/base64 -d < ${cfg.identityKeyFile} \
          > "${nodeDir}/data/ed25519_identity.new" )
      ${pkgs.coreutils}/bin/mv -f "${nodeDir}/data/ed25519_identity.new" \
        "${nodeDir}/data/ed25519_identity"

      ( umask 077
        ${pkgs.coreutils}/bin/base64 -d < ${cfg.identityPublicKeyFile} \
          > "${nodeDir}/data/ed25519_identity.pub.new" )
      ${pkgs.coreutils}/bin/mv -f "${nodeDir}/data/ed25519_identity.pub.new" \
        "${nodeDir}/data/ed25519_identity.pub"

      echo "nym-node: identity restored from the secret store"
    ''}
  '';

  start = pkgs.writeShellScript "nym-node-start" ''
    set -euo pipefail
    ${announceIps}
    ${lib.optionalString (cfg.publicIps == [ ]) ''
      echo "nym-node: announcing $NYMNODE_PUBLIC_IPS"
    ''}
    exec ${cfg.package}/bin/nym-node --no-banner run \
      --deny-init --write-changes --accept-operator-terms-and-conditions
  '';

  # The node reads public_ips once at startup and signs them into its
  # self-described API (the field is literally `static_information`), which the
  # nym-api scrapes into the routing topology. So a changed address is not
  # picked up until the service restarts — dynamic DNS alone would keep the node
  # discoverable while peers still routed packets to the old, dead address.
  # This compares what the node is announcing against reality and restarts it on
  # a mismatch. Only needed when the address is auto-detected.
  ipSync = pkgs.writeShellScript "nym-node-ip-sync" ''
    set -euo pipefail
    ${pkgs.systemd}/bin/systemctl is-active --quiet nym-node.service || exit 0

    announced=$(${pkgs.curl}/bin/curl -sf --max-time 10 \
      http://127.0.0.1:${toString httpPort}/api/v1/host-information \
      | ${pkgs.jq}/bin/jq -r '.data.ip_address[0] // empty') || exit 0
    [ -n "$announced" ] || exit 0

    current=$(${resolveIp}) || exit 0

    if [ "$announced" != "$current" ]; then
      echo "nym-node: announced address $announced is stale (now $current); restarting"
      ${pkgs.systemd}/bin/systemctl restart nym-node.service
    fi
  '';
in
{
  options.services.nym-node = {
    enable = lib.mkEnableOption "Nym mixnet node";

    package = lib.mkPackageOption pkgs "nym" { };

    id = lib.mkOption {
      type = lib.types.str;
      default = "default-nym-node";
      description = ''
        Node id, determining its state location under {file}`${stateDir}`.
        Changing it after bonding orphans the existing identity.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [ "mixnode" "entry-gateway" "exit-gateway" ];
      default = "mixnode";
      description = ''
        Node functionality. Exactly one mode may be assigned; a node
        advertising several is non-routable.
      '';
    };

    acceptTermsAndConditions = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether you accept the Nym operator terms and conditions
        (<https://nymtech.net/terms-and-conditions/operators/v1.0.0>).
        A node that has not accepted them is excluded from the active set.
      '';
    };

    identityKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "config.sops.secrets.\"nym/identity-key-b64\".path";
      description = ''
        File holding the node's **base64-encoded** ed25519 private identity
        key, readable by the `nym-node` user. Typically a sops-nix secret.

        This key is what the mixnet contract bonds to. Supplying it here makes
        the node reproducible — a rebuilt or restored host recovers its bond
        rather than coming up as an unbonded stranger. When null, the node
        generates its own identity on first start, and it exists only on that
        host's disk.

        Base64 rather than raw PEM because nym-node writes CRLF line endings
        that YAML block scalars silently rewrite, corrupting the key.
      '';
    };

    identityPublicKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File holding the base64-encoded ed25519 public identity key matching
        {option}`services.nym-node.identityKeyFile`. Required alongside it.
      '';
    };

    publicIps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "104.185.136.220" ];
      description = ''
        Addresses announced to the network; these become the routing addresses
        that peers send Sphinx packets to. When empty, the node's egress address
        is resolved at each service start instead.
      '';
    };

    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "nym.barbieri.world";
      description = ''
        DNS name announced alongside the public addresses.

        Strongly recommended on a connection without a static IP. The mixnet
        contract stores this node's `host` on-chain, and the nym-api uses it to
        discover the node's self-described API. If that host is a bare IP, an
        ISP address change makes the node undiscoverable until a wallet
        transaction updates the contract. A hostname kept current by dynamic
        DNS keeps the on-chain value stable and lets the address float.
      '';
    };

    location = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "US";
      description = "Physical location of the server, as a country name or ISO 3166 code.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the ports this node's mode listens on.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.acceptTermsAndConditions;
        message = ''
          services.nym-node.acceptTermsAndConditions must be true; a node that
          has not accepted them is excluded from the active set and earns nothing.
        '';
      }
      {
        assertion = (cfg.identityKeyFile == null) == (cfg.identityPublicKeyFile == null);
        message = ''
          services.nym-node.identityKeyFile and identityPublicKeyFile must be
          set together; nym-node reads both and will not derive one from the other.
        '';
      }
    ];

    users.users.nym-node = {
      isSystemUser = true;
      group = "nym-node";
      home = stateDir;
    };
    users.groups.nym-node = { };

    systemd = {
      services.nym-node = {
        description = "Nym mixnet node (${cfg.mode})";
        documentation = [ "https://nym.com/docs/operators" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          HOME = stateDir;
          NYMNODE_ID = cfg.id;
          NYMNODE_MODE = cfg.mode;
        }
        // lib.optionalAttrs (cfg.publicIps != [ ]) {
          NYMNODE_PUBLIC_IPS = lib.concatStringsSep "," cfg.publicIps;
        }
        // lib.optionalAttrs (cfg.hostname != null) { NYMNODE_HOSTNAME = cfg.hostname; }
        // lib.optionalAttrs (cfg.location != null) { NYMNODE_LOCATION = cfg.location; };

        serviceConfig = {
          ExecStartPre = seed;
          ExecStart = start;
          User = "nym-node";
          Group = "nym-node";
          StateDirectory = "nym-node";
          StateDirectoryMode = "0700";
          WorkingDirectory = stateDir;

          LimitNOFILE = 65536;      # one socket per peer; upstream requires this
          KillSignal = "SIGINT";    # SIGTERM is not handled gracefully
          Restart = "on-failure";   # nym-node exits if the nym-api is unreachable
          RestartSec = 30;

          NoNewPrivileges = true;
          CapabilityBoundingSet = [ "" ];
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
        };
      };

      # Watch for the host's address changing under a running node. Five minutes
      # matches the cadence of a typical dynamic-DNS updater, so the DNS record
      # and the announced address converge at roughly the same time.
      services.nym-node-ip-sync = lib.mkIf (cfg.publicIps == [ ]) {
        description = "Restart nym-node when this host's public IP changes";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ipSync;
        };
      };

      timers.nym-node-ip-sync = lib.mkIf (cfg.publicIps == [ ]) {
        description = "Periodic public IP check for nym-node";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "10min";
          OnUnitActiveSec = "5min";
          RandomizedDelaySec = "60";
        };
      };
    };

    # Default bind ports per mode. A mixnode leaves the client websocket (9000)
    # and Lewes Protocol (41264/51264) listeners closed, so opening them would
    # punch holes to nothing.
    networking.firewall = lib.mkIf cfg.openFirewall (
      let gateway = cfg.mode != "mixnode"; in {
        allowedTCPPorts = [ 1789 1790 httpPort ] ++ lib.optionals gateway [ 9000 41264 ];
        allowedUDPPorts = [ 1789 ] ++ lib.optionals gateway [ 51264 ];
      }
    );
  };
}
