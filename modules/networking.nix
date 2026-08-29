# Name resolution + interface naming for every host.
#
# - dnscrypt-proxy = sole owner of /etc/resolv.conf (hard invariant)
# - anything else wanting to answer names delegates in via forwarding rules, never writes resolvconf

{ config, lib, pkgs, ... }:

let
  cfg = config.networking.hostile;

  tailscaleEnabled = config.services.tailscale.enable;
  magicDnsIp = "100.100.100.100";
  tailnetDomain = "vaquita-altair.ts.net";  # `tailscale dns status`

  # measured, not inferred from NM state edges: also catches backoff stuck for other reasons
  # (suspend/resume, upstream outage), stays quiet on AP roams that leave the resolver healthy
  dnsRecoverScript = pkgs.writeShellScript "dnscrypt-recover" ''
    set -u

    [ "''${2:-}" = "connectivity-change" ] || exit 0
    [ "''${CONNECTIVITY_STATE:-}" = "FULL" ] || exit 0

    stamp=/run/dnscrypt-recover.stamp
    cooldown=120
    now=$(${pkgs.coreutils}/bin/date +%s)

    # flapping link re-emits connectivity-change; a restart that did not help will not help twice
    if [ -r "$stamp" ]; then
      last=$(${pkgs.coreutils}/bin/cat "$stamp" 2>/dev/null || echo 0)
      if [ $(( now - last )) -lt "$cooldown" ]; then
        exit 0
      fi
    fi

    # fails fast during backoff (SERVFAIL/REFUSED) → ~free when healthy
    # dig exits 0 on SERVFAIL, hence the emptiness test
    answer=$(${pkgs.dnsutils}/bin/dig +short +timeout=2 +tries=1 \
      @127.0.0.1 example.com A 2>/dev/null || true)
    [ -n "$answer" ] && exit 0

    # costs the 4096-entry cache + a fresh certification round
    ${pkgs.coreutils}/bin/echo "$now" > "$stamp"
    ${pkgs.systemd}/bin/systemctl restart dnscrypt-proxy.service
  '';
in
{
  options.networking.hostile = {
    enable = lib.mkEnableOption ''
      handling for networks that intercept traffic before authenticating you —
      school, hotel and airport wifi. Adds an isolated captive-portal browser
      and recovery for the encrypted resolver afterwards
    '';

    interface = lib.mkOption {
      type = lib.types.str;
      example = "wlp0s20f3";
      description = ''
        Physical network interface the portal lives behind. The SOCKS proxy is
        bound to it directly so portal traffic bypasses any overlay routes.
      '';
    };
  };

  config = {
    networking.networkmanager.enable = true;

    services.dnscrypt-proxy = {
      enable = true;

      settings = {
        # `dnscrypt-proxy -list` for candidates. All DoH/:443 (least-blocked port).
        # - >1 server: no query answered until ≥1 certified → thin pool = total outage
        # - pinning bypasses require_* entirely (proxy.go `else if`), so these are hand-vetted:
        #   all three advertise DNSSEC + no-log + no-filter. `google` is excluded: no-log = false
        server_names = [
          "cloudflare"
          "quad9-doh-ip4-port443-nofilter-pri"
          "mullvad-doh"
        ];

        # inert while server_names is pinned; guards the fallback if the pins are ever dropped
        require_dnssec = true;

        # portals handled below, so this stays unconditional
        ignore_system_dns = true;

        # plaintext UDP/53, resolves stamp hostnames pre-encryption → must not need DoH itself
        bootstrap_resolvers = [ "9.9.9.11:53" "1.1.1.1:53" ];

        # ts.net names + coordination-server split-DNS routes; plaintext rides the tunnel
        forwarding_rules = toString (
          builtins.toFile "forwarding-rules.txt" (
            lib.optionalString tailscaleEnabled "ts.net ${magicDnsIp}"
          )
        );

        # REAL addresses, not fakes: probe HTTP must leave the box for the portal's transparent
        # proxy to intercept → NM classifies link `portal`, not `limited`
        # requires connectivity.uri below; NM issues no probe at all without one
        captive_portals.map_file = toString (
          builtins.toFile "captive-portals.txt" ''
            captive.apple.com 17.253.109.201,17.253.113.202
            connectivitycheck.gstatic.com 216.239.32.117,216.239.34.117,216.239.36.117,216.239.38.117
            detectportal.firefox.com 34.107.221.82
            www.msftconnecttest.com 13.107.4.52
            dns.msftncsi.com 131.107.255.255
            nmcheck.gnome.org 209.51.188.128
            connectivity-check.ubuntu.com 34.117.59.81
            network-test.debian.org 130.89.148.77
          ''
        );
      };
    };

    # NixOS ships no [connectivity] section, and NM disables checking when the uri is blank —
    # it then fakes FULL on activation, so `portal` is never reported and the recovery script
    # below fires while still behind the portal instead of after authenticating
    networking.networkmanager.settings.connectivity = {
      uri = "http://nmcheck.gnome.org/check_network_status.txt";
      interval = 300;
    };

    networking.networkmanager.dns = "none";
    networking.nameservers = [ "127.0.0.1" ];

    # tailscaled's resolvconf layer outranks `static` → MagicDNS would front dnscrypt-proxy and
    # reach it only via a "system default" it reports as unreadable. Take the layer away; the
    # ts.net forwarding rule above delegates back explicitly.
    services.tailscale.extraSetFlags = lib.mkIf tailscaleEnabled [ "--accept-dns=false" ];

    # --accept-dns=false also drops the search domain (bare `ssh arbei`)
    networking.search = lib.mkIf tailscaleEnabled [ tailnetDomain ];

    # ethernet keeps kernel eth0/eth1; wifi (Type=wlan) and bridges (DEVTYPE=bridge) never match
    # - `keep` fails for kernel-enumerated devs → ID_NET_NAME = current name → rename is a no-op
    # - veth/tap DO match (no DEVTYPE → falls back to `ether`), but are userspace-named so `keep`
    #   succeeds → no-op. MACAddressPolicy restated from 99-default.link (first match wins, no
    #   merge); inert for them anyway, addr_assign_type=NET_ADDR_SET short-circuits it
    # - 2+ ethernet NICs → eth0/eth1 by probe order, racy across boots (≤1 per host here)
    systemd.network.links."10-ethernet-legacy-names" = {
      matchConfig.Type = "ether";
      linkConfig = {
        NamePolicy = "keep";
        MACAddressPolicy = "persistent";
      };
    };

    # google/captive-browser: throwaway incognito Chromium, all traffic through a local SOCKS
    # server that resolves names itself off the DHCP-advertised resolver
    #
    # - resolv.conf untouched, dnscrypt-proxy untouched
    # - plaintext-DNS blast radius = one incognito window
    # - SO_BINDTODEVICE also keeps portal traffic off tailscale0/nebula.mesh (unprivileged
    #   since Linux 5.7, so the module needs no wrapper)
    # - interface must be the PRIMARY kernel name: the dhcp-dns scrape is `nmcli dev show`,
    #   which does not resolve altnames and would silently yield no resolver
    programs.captive-browser = lib.mkIf cfg.enable {
      enable = true;
      inherit (cfg) interface;
      # dhcp-dns defaults to an `nmcli dev show <iface>` scrape — correct under NetworkManager
    };

    networking.networkmanager.dispatcherScripts = lib.mkIf cfg.enable [
      {
        type = "basic";
        source = dnsRecoverScript;
      }
    ];
  };
}
