# Zcash mainnet validator (trusted validator for zaino-prod)
{ pkgs, ... }:

let
  # E5-1650 v4
  zebrad = pkgs.callPackage ../../pkgs/zebrad.nix { targetCpu = "broadwell"; };

  # data/ seeded from ztest snapshot
  zebraDir = "/mnt/md0/zcash";
  zebradConfig = (pkgs.formats.toml { }).generate "zebrad.toml" {
    network = {
      network = "Mainnet";
      listen_addr = "0.0.0.0:8233";
      # Zakura's default (Zebra: 25): wider tip + mempool view for zaino
      # - Zebra's compile-time limits: outbound 3× (300), inbound 5× (500)
      peerset_initial_target_size = 100;
      # Peer address cache (default ~/.cache: no home + ProtectHome = never written)
      cache_dir = "${zebraDir}/data";
      # Own peers (zaino-prod, ztest zebrads) never lose to full public slots
      # - tailscale0 only (firewall): tailnet ACL = who reaches it
      reserved_listener = {
        listen_addr = "0.0.0.0:8234";
        slots = 16;
      };
    };
    state.cache_dir = "${zebraDir}/data";
    # Unauthenticated: 8232 + 8230 open on tailscale0 + nebula.mesh only (tailnet ACL = auth)
    rpc = {
      listen_addr = "0.0.0.0:8232";
      enable_cookie_auth = false;
      # zaino tip + mempool push streams (unset = zaino polls every 1 s)
      indexer_listen_addr = "0.0.0.0:8230";
    };
    # stdout = journald pipe, not a tty (use_color alone → no color)
    tracing.force_use_color = true;
  };
in
{
  users.users.zebra = {
    isSystemUser = true;
    group = "zebra";
  };
  users.groups.zebra = {};

  networking.firewall = {
    allowedTCPPorts = [ 8233 ];
    # Not trusted: tailnet admins hold a "*" grant → only zebrad RPC + indexer exposed
    interfaces.tailscale0.allowedTCPPorts = [ 8232 8230 8234 ];
  };

  systemd.services.zebrad = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.RequiresMountsFor = zebraDir;
    serviceConfig = {
      ExecStart = "${zebrad}/bin/zebrad --config ${zebradConfig} start";
      User = "zebra";
      Group = "zebra";
      Restart = "on-failure";
      # RocksDB flush on SIGTERM
      TimeoutStopSec = 300;
      # ~17k SST files in the mainnet state
      LimitNOFILE = 1048576;
      ProtectSystem = "strict";
      ReadWritePaths = [ "${zebraDir}/data" ];
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
}
