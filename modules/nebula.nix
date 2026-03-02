# Nebula mesh overlay network
# Subnet: 100.64.0.0/24 (CGNAT range — avoids conflicts with RFC1918 private networks)
# Lighthouse: elicb-home-server (100.64.0.1)
{ config, lib, ... }:

let
  cfg = config.services.nebula.networks.mesh;
in
{
  options.nebula.isLighthouse = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether this host is the Nebula lighthouse";
  };

  config = {
    services.nebula.networks.mesh = {
      enable = true;
      ca = config.sops.secrets."nebula/ca-crt".path;
      cert = config.sops.secrets."nebula/host-crt".path;
      key = config.sops.secrets."nebula/host-key".path;

      isLighthouse = config.nebula.isLighthouse;
      isRelay = config.nebula.isLighthouse;

      staticHostMap = {
        "100.64.0.1" = [
          "104.185.136.220:4242"
          "192.168.1.220:4242"
        ];
      };

      lighthouses = lib.mkIf (!config.nebula.isLighthouse) [
        "100.64.0.1"
      ];

      listen = {
        port = if config.nebula.isLighthouse then 4242 else 0;
      };

      firewall = {
        outbound = [
          { port = "any"; proto = "any"; host = "any"; }
        ];
        inbound = [
          { port = "any"; proto = "any"; host = "any"; }
        ];
      };

      settings = {
        punchy = {
          punch = true;
          respond = true;
        };
      };
    };

    # Open lighthouse port on the server
    networking.firewall.allowedUDPPorts = lib.mkIf config.nebula.isLighthouse [
      4242
    ];
  };
}
