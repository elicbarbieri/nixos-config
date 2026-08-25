# Dynamic DNS — keeps barbieri.world records pointed at this host's current
# public IP, so services can be reached by name on a connection without a
# static address.
#
# This exists primarily for the Nym node: the mixnet smart contract stores a
# node's `host` on-chain, and changing it costs a wallet transaction. Bonding
# with a name instead of an IP means the on-chain value never has to change.
#
# The records MUST stay DNS-only (grey cloud), never proxied: Cloudflare's
# proxy only handles HTTP(S), so a proxied record would hand out Cloudflare's
# address and silently black-hole the mixnet's Sphinx traffic on 1789/1790.
# `proxied` defaults to false; it is set explicitly here because getting it
# wrong breaks the node in a way that is hard to diagnose.
#
# NOT YET ACTIVE. To turn on, in this order:
#   1. Register barbieri.world and move it to Cloudflare's nameservers.
#   2. Create a Cloudflare API token scoped to Zone:DNS:Edit on that zone only.
#   3. `sops hosts/elicb-home-server/secrets.yaml` and add, as the raw token
#      with no "CLOUDFLARE_API_TOKEN=" prefix (the module rejects that):
#        cloudflare:
#            api-token: <token>
#   4. Uncomment the sops secret and the ./ddns.nix import in default.nix, and
#      `hostname` in nym.nix.
# The build deliberately fails until step 3: sops verifies at build time that
# every declared secret exists.
{ config, ... }:
{
  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets."cloudflare/api-token".path;
    domains = [
      "nym.barbieri.world"        # mixnet node — MUST stay DNS-only
      "photos.barbieri.world"     # Immich, via nginx
      "requests.barbieri.world"   # Jellyseerr, via nginx
      "mesh.barbieri.world"       # Nebula lighthouse underlay address
    ];
    proxied = false;
    ipv4 = true;
    ipv6 = false;      # no IPv6 on this connection; avoids failing AAAA updates
    deleteMissing = false;
  };
}
