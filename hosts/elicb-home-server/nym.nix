# Nym mixnet node — mixes and forwards Sphinx packets for the mixnet.
#
# IMPORTANT — this host has no static IP, and that interacts with how Nym works:
#
#   * The mixnet smart contract stores this node's `host` ON-CHAIN. The nym-api
#     uses it to discover the node's self-described API. Changing it needs a
#     wallet transaction.
#   * The addresses the node announces (public_ips) are scraped from that API
#     into the routing topology — they are what peers send packets to. The node
#     signs a force-refresh broadcast to the nym-api on every start, so a
#     restart propagates a new address within minutes.
#
# So: bond with a HOSTNAME, never a bare IP. Then the on-chain value never has
# to change, and the floating address is handled entirely by the restart above.
# Bonding with a bare IP means every ISP address change takes the node offline
# until you send a wallet transaction to update the contract.
#
# That is wired up: ddns.nix keeps nym.barbieri.world pointing here. Bond using
# the NAME, not the address it currently resolves to.
{ config, pkgs, ... }:
{
  imports = [ ../../modules/nym-node.nix ];

  services.nym-node = {
    enable = true;
    id = "elicb-home-server";
    mode = "mixnode";
    acceptTermsAndConditions = true;
    location = "US";

    # Bond with THIS NAME, not an IP, so an address change never needs a
    # wallet transaction. Kept current by cloudflare-dyndns (see ddns.nix).
    hostname = "nym.barbieri.world";

    # publicIps left empty: resolved at each start, then propagated to the
    # nym-api by the node's signed force-refresh broadcast.

    # The bonding identity lives in sops, not on this host's disk alone. The
    # bond is tied to this key, so a lost disk without it means unbonding and
    # starting over on reputation; restored from here, a rebuilt host comes
    # back as the same node.
    identityKeyFile = config.sops.secrets."nym/identity-key-b64".path;
    identityPublicKeyFile = config.sops.secrets."nym/identity-key-pub-b64".path;
  };

  environment.systemPackages = [ pkgs.nym ];

  # Operating notes
  # ---------------
  # Bonding identity: 8nBTihhrqzgbboiyCJGwQDmxiLh2rz57MoMWiZPLTcFU
  # Already generated and stored in sops; to replace it, see modules/nym-node.nix.
  #
  # The wallet is never needed on this host. To sign the payload it hands back:
  #
  #   sudo -u nym-node env HOME=/var/lib/nym-node \
  #     nym-node --no-banner sign --id elicb-home-server --contract-msg <payload>
  #
  # The data dir also holds a `cosmos_mnemonic` — a node-local account, NOT the
  # bonding wallet. Do not fund it.
  #
  # Forward 1789 TCP+UDP, 1790 TCP and 8080 TCP at the router; unreachable nodes
  # get blacklisted. Check status at https://harbourmaster.nymtech.net or
  # https://nym.com/explorer (explorer.nymtech.net is dead).
}
