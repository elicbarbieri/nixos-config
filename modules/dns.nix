# Encrypted DNS via dnscrypt-proxy (DoH over 443).

{ config, lib, ... }:

let
  cfg = config.dns;
in
{
  options.dns = {
    cloakingRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "*.crc.testing 100.64.0.3" ];
      description = ''
        Lines for dnscrypt-proxy's cloaking-rules file, which returns a fixed
        address for a name (the equivalent of dnsmasq's `address=/name/ip`).
      '';
    };

    forwardingRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "crc.testing 192.168.130.11" ];
      description = ''
        Lines for dnscrypt-proxy's forwarding-rules file, which routes a zone to
        a specific resolver (the equivalent of dnsmasq's `server=/name/ip`).
      '';
    };
  };

  config = {
    services.dnscrypt-proxy = {
      enable = true;

      settings = {
        # `dnscrypt-proxy -list` to see available
        server_names = [ "cloudflare" "google" ];

        require_dnssec = true;

        # Never fall back to the DHCP-provided resolver.
        ignore_system_dns = true;

        bootstrap_resolvers = [ "9.9.9.11:53" "8.8.8.8:53" ];

        cloaking_rules = toString (
          builtins.toFile "cloaking-rules.txt" (lib.concatStringsSep "\n" cfg.cloakingRules)
        );

        forwarding_rules = toString (
          builtins.toFile "forwarding-rules.txt" (lib.concatStringsSep "\n" cfg.forwardingRules)
        );

        # Answer the OS connectivity-check names locally so captive-portal
        # splash pages stay reachable and NetworkManager can still detect a
        # portal
        captive_portals.map_file = toString (
          builtins.toFile "captive-portals.txt" ''
            captive.apple.com 17.253.109.201,17.253.113.202
            connectivitycheck.gstatic.com 216.239.32.117,216.239.34.117,216.239.36.117,216.239.38.117
            detectportal.firefox.com 34.107.221.82
            www.msftconnecttest.com 13.107.4.52
            dns.msftncsi.com 131.107.255.255
            nmcheck.gnome.org 209.51.188.128
          ''
        );
      };
    };

    # NetworkManager must not overwrite resolv.conf with DHCP-provided servers
    networking.networkmanager.dns = "none";
    networking.nameservers = [ "127.0.0.1" ];
  };
}
