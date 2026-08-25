# Nginx reverse proxy with TLS for barbieri.world subdomains
#
# Routes:
#   photos.barbieri.world   → Immich     (127.0.0.1:2283)
#   requests.barbieri.world → Jellyseerr (127.0.0.1:5055)
#
# Certificates use the DNS-01 challenge rather than HTTP-01. On a residential
# connection inbound port 80 is frequently blocked or unforwarded, which would
# make HTTP-01 fail intermittently and silently — and renewals fail 60 days
# later, long after anyone remembers changing this. DNS-01 proves control via
# the Cloudflare zone instead, so certificate issuance no longer depends on
# inbound reachability at all. It also means a cert can be obtained before
# port forwarding is in place.
#
# Only services with their own authentication are exposed here. The *arr stack,
# Homarr and the Deluge web UI are deliberately absent: they are unauthenticated
# admin surfaces and belong on the Tailscale/Nebula mesh, not on public DNS.
{ config, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "elicb@barbieri.world";
      dnsProvider = "cloudflare";
      # systemd reads EnvironmentFile as root before the unit drops privileges,
      # so this stays root-owned 0400.
      environmentFile = config.sops.templates."acme-cloudflare.env".path;
    };

    # Declared explicitly rather than via nginx's `enableACME`, which forces
    # HTTP-01: it sets `webroot` and actively overrides `dnsProvider` back to
    # null, so an inherited DNS-01 setting is silently discarded. Vhosts below
    # reference this with `useACMEHost`.
    #
    # One certificate covers both names, so there is a single renewal to reason
    # about. Names are listed explicitly rather than using a wildcard: DNS-01
    # would permit `*.barbieri.world`, but that puts every present and future
    # subdomain behind one key for no benefit here. Adding a name later is a
    # one-line change.
    certs."barbieri-world" = {
      domain = "photos.barbieri.world";
      extraDomainNames = [ "requests.barbieri.world" ];
      group = "nginx";
    };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    virtualHosts = {
        # Don't serve anything for a Host header we don't recognise.
      "_" = {
        default = true;
        rejectSSL = true;
        locations."/".return = "444";
      };

      # Immich — large uploads need generous limits
      "photos.barbieri.world" = {
        forceSSL = true;
        useACMEHost = "barbieri-world";
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout 600s;
          '';
        };
      };

      # Jellyseerr — authenticates against Plex accounts
      "requests.barbieri.world" = {
        forceSSL = true;
        useACMEHost = "barbieri-world";
        locations."/" = {
          proxyPass = "http://127.0.0.1:5055";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
