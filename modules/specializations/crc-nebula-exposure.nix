# CRC → Nebula mesh exposure
#
# Bridges the Nebula overlay to the CRC libvirt network so mesh peers can reach the
# cluster API + ingress. Lives in the kubernetes specialization, not base, because the
# `crc` bridge and 192.168.130.11 only exist while the specialization is active

{ config, lib, ... }:

let
  crcNode = "192.168.130.11"; # CRC system-mode node IP, fixed by CRC
  ports = "6443,80,443";      # API + ingress router (Routes ride 80/443)
in
{
  # extraCommands is the iptables escape hatch; the nftables backend rejects it. Fail at
  # build time rather than silently leaving mesh peers unable to reach the cluster.
  assertions = [{
    assertion = !config.networking.nftables.enable;
    message = "crc-nebula-exposure uses iptables extraCommands; incompatible with the nftables backend.";
  }];

  # libvirt's nat network enables this at runtime, but arming the forward must not depend on a VM already being up.
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.firewall = {

    # libvirt's nat-mode network appends a catch-all `-o crc -j REJECT`, so this accept
    # for the inbound-initiated flow must sit above it (-I ... 1). Replies need no rule:
    # libvirt already accepts `-s 192.168.130.0/24 -i crc`, and we deliberately do not
    # SNAT, so the node sees the real mesh source and — its default gw being this host —
    # the return path is guaranteed and conntrack reverses the DNAT.
    # mkAfter so the -I FORWARD 1 insert runs after any other merged extraCommands,
    # keeping our rule deterministically at the top of the chain.
    extraCommands = lib.mkAfter ''
      iptables -t nat -A PREROUTING -i nebula.mesh -p tcp -m multiport --dports ${ports} \
        -j DNAT --to-destination ${crcNode}

      iptables -I FORWARD 1 -i nebula.mesh -o crc -d ${crcNode} -p tcp \
        -m multiport --dports ${ports} -j ACCEPT
    '';

    extraStopCommands = ''
      iptables -t nat -D PREROUTING -i nebula.mesh -p tcp -m multiport --dports ${ports} \
        -j DNAT --to-destination ${crcNode} 2>/dev/null || true
      iptables -D FORWARD -i nebula.mesh -o crc -d ${crcNode} -p tcp \
        -m multiport --dports ${ports} -j ACCEPT 2>/dev/null || true
    '';
  };
}
