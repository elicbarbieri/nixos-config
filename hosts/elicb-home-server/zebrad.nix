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
    };
    state.cache_dir = "${zebraDir}/data";
    # Unauthenticated: 8232 open on tailscale0 + nebula.mesh only (tailnet ACL = auth)
    rpc = {
      listen_addr = "0.0.0.0:8232";
      enable_cookie_auth = false;
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
    # Not trusted: tailnet admins hold a "*" grant → only zebrad RPC exposed
    interfaces.tailscale0.allowedTCPPorts = [ 8232 ];
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
