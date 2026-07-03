# CRC / OpenShift Local (OKD) specialization
#
# Runs CodeReady Containers declaratively on NixOS. CRC assumes a mutable FHS
# host and imperatively mutates it during `crc setup`.  We apply some hacks:

# - CRC checks membership of "libvirt" group
# - we use `network-mode system` w/ libvirt networking to avoid using user mode networking with the
#   immutable nix store
# - Writing /etc NetworkManager+dnsmasq files — CRC's system-mode network writes here for inventory
#   purposes and identifying the routes to vms
#
# One-Time Set
#     crc config set preset okd
#     crc config set network-mode system
#     crc config set consent-telemetry no
#     crc config set disk-size 100
#     crc setup
#     crc start

{ config, pkgs, lib, ... }:

let

  # Add libvirt to library path of the CRC go binary
  crcWithLibvirt = pkgs.symlinkJoin {
    name = "crc-libvirt-wrapped";
    paths = [ pkgs.crc ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/crc \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.libvirt ]}
    '';
  };
in
{
  environment.systemPackages = [ crcWithLibvirt ];

  users.groups.libvirt = { };
  users.users.elicb.extraGroups = [ "libvirt" ];

  # CRC needs virtiofsd to share a host directory into the VM
  virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];

  # dnsmasq so split-DNS for *.crc.testing and *.apps-crc.testing resolves to the CRC VM.
  networking.networkmanager.dns = "dnsmasq";

  # NetworkManager has no native option for dnsmasq.d entries, so we write the split-DNS.  CRC in system mode is always .11
  environment.etc."NetworkManager/dnsmasq.d/crc.conf".text = ''
    server=/apps-crc.testing/192.168.130.11
    server=/crc.testing/192.168.130.11
  '';

  # CRC's post-start runs the setuid `crc-admin-helper` to sync cluster hostnames
  # (api.crc.testing, console-openshift-console.apps-crc.testing, ...) into /etc/hosts
  environment.etc.hosts.mode = lib.mkForce "0644";

  networking.firewall.trustedInterfaces = [ "crc" ];
}
