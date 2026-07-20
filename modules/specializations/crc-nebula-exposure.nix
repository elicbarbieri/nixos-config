# CRC → Nebula mesh exposure
#
# Bridges the Nebula overlay to the CRC libvirt network so mesh peers can reach the
# cluster API + ingress. Lives in the kubernetes specialization, not base, because the
# `crc` bridge and 192.168.130.11 only exist while the specialization is active.
#
# Reaching the CRC guest from the mesh needs two rules on the host:
#
#   1. DNAT — mesh traffic to 6443/80/443 is rewritten to the CRC node. The
#      node's default gw is this host and we deliberately do not SNAT, so the
#      return path is guaranteed and conntrack reverses the DNAT; the reply is
#      accepted by libvirt's own `-s 192.168.130.0/24 -i crc -j ACCEPT`.
#
#   2. FORWARD ACCEPT — libvirt's NAT network installs `-o crc -j REJECT` (inside
#      LIBVIRT_FWI) to drop unsolicited inbound to the guest, and it -I-inserts the
#      FORWARD->LIBVIRT_FWI jump at the TOP of FORWARD on *every* network start.
#      So our ACCEPT must sit above that jump, and must be re-asserted after each
#      (re)start. No boot-time rule — NixOS-native (networking.nat.forwardPorts)
#      or raw — can win this ordering, because libvirt rebuilds its chains later,
#      at `crc start`, and buries anything placed earlier.
#
# Both rules therefore live in a libvirt *network hook*, which libvirt runs
# synchronously on network lifecycle events — the only race-free point to (re)apply
# them, and it ties the rules' lifetime to the crc network's. The hook is installed
# via `virtualisation.libvirtd.hooks.network`, which drops it in the dir libvirt
# actually reads on NixOS (/var/lib/libvirt/hooks/network.d, since libvirt is built
# with --sysconfdir=/var/lib — /etc/libvirt/hooks is NOT consulted here).

{ config, pkgs, lib, ... }:

let
  crcNode = "192.168.130.11"; # CRC system-mode node IP, fixed by CRC
  bridge = "crc";             # libvirt bridge for the crc network
  mesh = "nebula.mesh";       # inbound mesh interface
  ports = "6443,80,443";      # API + ingress router (Routes ride 80/443)

  # Rule specs as "<chain> <match...> <target>", reused for both add and delete so
  # the hook is idempotent. `-I <chain>` defaults to position 1 (top of the chain).
  dnatSpec = "PREROUTING -i ${mesh} -p tcp -m multiport --dports ${ports} -j DNAT --to-destination ${crcNode}";
  fwdSpec = "FORWARD -i ${mesh} -o ${bridge} -d ${crcNode} -p tcp -m multiport --dports ${ports} -j ACCEPT";

  networkHook = pkgs.writeShellScript "crc-nebula-network-hook" ''
    # libvirt network hook — argv: <network-name> <operation> <sub-op> <extra>.
    # Act only on the CRC network; ignore every other libvirt network.
    [ "$1" = "${bridge}" ] || exit 0

    ipt='${pkgs.iptables}/bin/iptables'

    # Drop every existing copy of a rule (guards against duplicates accumulating
    # across restarts) before we re-add it at the desired position.
    purge() { # $1 = table, $2.. = "<chain> <match...> <target>"
      table="$1"; shift
      while "$ipt" -t "$table" -D "$@" 2>/dev/null; do :; done
    }

    case "$2" in
      started|port-created)
        # DNAT lives in nat/PREROUTING, which libvirt never touches; re-asserted
        # here anyway so a single hook is the sole source of truth for both rules.
        purge nat ${dnatSpec}
        "$ipt" -t nat -A ${dnatSpec}

        # Insert the forward-accept at the top of FORWARD, above libvirt's freshly
        # (re)inserted jump to LIBVIRT_FWI. This op fires after libvirt has built
        # its rules, so position 1 is genuinely above the REJECT.
        purge filter ${fwdSpec}
        "$ipt" -I ${fwdSpec}
        ;;
      stopped)
        purge nat ${dnatSpec}
        purge filter ${fwdSpec}
        ;;
    esac
    exit 0
  '';
in
{
  # Our iptables rules assume libvirt is on its iptables backend and that the host
  # firewall is iptables too. With the nftables backend, libvirt builds a separate
  # `libvirt_network` nft table (no LIBVIRT_FWI chain) and iptables rules won't
  # interact as intended. Fail the build rather than silently breaking mesh access.
  assertions = [{
    assertion = !config.networking.nftables.enable;
    message = "crc-nebula-exposure targets the iptables backend; incompatible with networking.nftables.enable.";
  }];

  # Route between the mesh and crc bridges. libvirt also enables this at runtime,
  # but arming forwarding declaratively means it does not depend on a VM being up.
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Installs to /var/lib/libvirt/hooks/network.d/crc-nebula (a dir libvirt
  # dispatches natively). libvirtd only scans hooks at startup, so a first-ever
  # install requires a libvirtd restart — nixos-rebuild switch restarts the
  # service because this changes its preStart.
  virtualisation.libvirtd.hooks.network.crc-nebula = networkHook;
}
