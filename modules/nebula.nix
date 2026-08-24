# Nebula mesh overlay network
#
# Subnet: 10.99.0.0/24
#   .1  elicb-home-server  (lighthouse + relay)
#   .2  elicb-xps
#   .3  elicb-dell-desktop
#
# Deliberately RFC1918 rather than the 100.64.0.0/10 CGNAT range this mesh
# originally used. Tailscale allocates tailnet addresses from that same /10 and
# installs its per-peer routes in policy table 52, which the kernel consults
# before the main table (rule 5270 vs 32766). A Nebula subnet inside that /10
# can therefore be silently shadowed by a Tailscale peer that happens to be
# assigned an overlapping address — a failure that looks like nothing more than
# one host mysteriously dropping off the mesh.
#
# Host addresses are baked into each node's certificate, so changing `subnet`
# here also requires re-signing every host cert with the CA and updating the
# nebula/host-crt and nebula/host-key secrets for each host.
{ config, lib, ... }:

let
  subnet = "10.99.0.0/24";
  lighthouseAddr = "10.99.0.1";
  listenPort = 4242;

  # Candidate underlay addresses for the lighthouse, tried in order. Entries
  # that are not literal IPs are resolved in the background on
  # `static_map.cadence` (30s default), so the DNS name tracks a changing ISP
  # address without a rebuild, while the literal addresses keep the mesh working
  # if DNS is unavailable — including early in boot, before resolvers are up.
  lighthouseEndpoints = [
    "mesh.barbieri.world:${toString listenPort}"
    "104.185.136.220:${toString listenPort}"
    "192.168.1.220:${toString listenPort}"
  ];

  isLighthouse = config.nebula.isLighthouse;
in
{
  options.nebula.isLighthouse = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether this host is the mesh lighthouse. The lighthouse listens on a
      fixed port and relays traffic between peers that cannot hole-punch
      directly; every other host dials it.
    '';
  };

  config = {
    services.nebula.networks.mesh = {
      enable = true;
      ca = config.sops.secrets."nebula/ca-crt".path;
      cert = config.sops.secrets."nebula/host-crt".path;
      key = config.sops.secrets."nebula/host-key".path;

      inherit isLighthouse;
      isRelay = isLighthouse;

      staticHostMap = {
        "${lighthouseAddr}" = lighthouseEndpoints;
      };

      lighthouses = lib.mkIf (!isLighthouse) [ lighthouseAddr ];

      # Relay peer-to-peer traffic through the lighthouse when two NATed hosts
      # on different networks cannot hole-punch directly.
      relays = lib.mkIf (!isLighthouse) [ lighthouseAddr ];

      # The lighthouse needs a predictable port so peers can reach it. Everyone
      # else uses an ephemeral port, which is friendlier to NAT.
      listen.port = if isLighthouse then listenPort else 0;

      # Membership in the mesh is already gated by the CA: a host cannot join
      # without a certificate this CA signed. These rules therefore allow all
      # traffic between authenticated peers, and access control is done at the
      # host firewall instead.
      firewall = {
        outbound = [{ port = "any"; proto = "any"; host = "any"; }];
        inbound = [{ port = "any"; proto = "any"; host = "any"; }];
      };

      settings.punchy = {
        punch = true;
        respond = true;
      };
    };

    # Peers are authenticated by the mesh CA before any packet reaches the host,
    # so treat the tunnel as trusted rather than requiring every service to be
    # opened to the world to be reachable over the mesh.
    networking.firewall.trustedInterfaces = [ "nebula.mesh" ];

    networking.firewall.allowedUDPPorts = lib.mkIf isLighthouse [ listenPort ];
  };
}
