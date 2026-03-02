# Nginx reverse proxy with ACME TLS for barbieri.world subdomains
#
# Routes:
#   photos.barbieri.world → Immich (127.0.0.1:2283)
{ ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "elicb@barbieri.world";
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    # Immich — large uploads need generous limits
    virtualHosts."photos.barbieri.world" = {
      forceSSL = true;
      enableACME = true;
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
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
