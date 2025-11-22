# Home Server Configuration
{ config, pkgs, nixvim, ... }:

let
  base-packages = import ../../modules/base-packages.nix { inherit pkgs nixvim; };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # Existing RAID5 array (md0) - preserved, not managed by disko
  # UUID: b0de9c80:a5ac423d:61f20052:ba33e57e (RAID array UUID)
  # Filesystem UUID: d9b99d85-6a26-4637-b8db-342f465b58f8
  fileSystems."/mnt/md0" = {
    device = "/dev/disk/by-uuid/d9b99d85-6a26-4637-b8db-342f465b58f8";
    fsType = "ext4";
  };

  # Existing deepstor data disk - preserved, not managed by disko
  # Using label for simplicity (UUID: e526b56b-8e10-47ea-b3da-e0c344357f07)
  fileSystems."/mnt/deepstor" = {
    device = "/dev/disk/by-label/deepstor";
    fsType = "ext4";
  };

  # Enable mdadm for RAID5 array management
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    ARRAY /dev/md0 UUID=b0de9c80:a5ac423d:61f20052:ba33e57e
  '';

  # Install base packages + btrfs tools for snapshot management
  environment.systemPackages = base-packages.common ++ (with pkgs; [
    btrfs-progs  # For btrfs subvolume and snapshot management
  ]);

  # Host-specific configuration
  networking.hostName = "elicb-home-server";

  # Additional groups for server functionality
  users.users.elicb.extraGroups = [ "docker" "deluge" ];

  # SSH authorized keys
  users.users.elicb.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgDA8a/EFrgf2Vzr7+Qnh1UBzu/l5xX1e/vMtNs1hiwdPCfjv/MisPidTlvU5X1tUvAGUZodX871FdnNX1EfRbWxX2kvURaM0GPJRhzCI+vmohH365qix4/HDUCVCFMGwDV8J6n3SgOYoOfGTOaFt+Q1Xmw8hHQfGOdxrh2AYWsGEjOhen4lPhZVDKzUB6+ZQmFnDWS9nd7ds8YOJ6ryxgdEICaD+rPSCDaRDJy5iHM4hyNITTm50pCR+oeYZ1Ay8q5ec3XEmpFGQSw4Roz5LV95TIfb0U7In8TTPGFrIPkxsvrEhBIdAVTcJXctHC4Ei2kOCAz0ArM0qA/L/Lpu7BNb/7eNHICEekTGx7v2tPqiE8+zTU8r7P2f5jWLcVYcJX8Xmj9xzBccR8Jo21+oujwo9Z2Yae94cdDkQeSQpASi/lZo7u7X7dfmUU70pypaDJhNwJv2GGRjRUPHFxVDMkRWJTGI0+QG8MoPMneOuolfOi7oSfrJ8/BrW3SlOOFgd73pvplZ4op/EwPCNKPgsig8oh24KOPxOD3C4hOPVr5OK7TVhG0KuHGeOkUgbtdC7RBcmwXWCKbmZ6xfrxXwvtuagWp5/6d3Cu96K2Q3dhVbh/DSaJH1uMKnEW0fsuB8xXj/YI5GrpaLIFNBpIibMiwOh3EJQQCawldKBJFRN3WQ== elicb@elicb-xps-wsl"
  ];

  # Server-specific services
  virtualisation.docker.enable = true;

  services.deluge = {
    enable = true;
    web.enable = true;
  };


  # WireGuard network namespace configuration
  # Creates an isolated network namespace with only WireGuard connectivity
  systemd.services."netns@" = {
    description = "%I network namespace";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
      ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
    };
  };

  # WireGuard interface within the wg network namespace
  systemd.services.wg = {
    description = "wg network interface";
    bindsTo = [ "netns@wg.service" ];
    requires = [ "network-online.target" ];
    after = [ "netns@wg.service" "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = with pkgs; writers.writeBash "wg-up" ''
        set -e
        ${iproute2}/bin/ip link add wg0 type wireguard
        ${iproute2}/bin/ip link set wg0 netns wg

        # TODO: Configure your WireGuard VPN settings here
        # ${iproute2}/bin/ip -n wg address add <your-vpn-ip/cidr> dev wg0
        # ${iproute2}/bin/ip netns exec wg \
        #   ${wireguard-tools}/bin/wg setconf wg0 /root/wireguard.conf

        ${iproute2}/bin/ip -n wg link set wg0 up
        ${iproute2}/bin/ip -n wg link set lo up

        # Route all traffic through wg0 - this ensures no leaks
        ${iproute2}/bin/ip -n wg route add default dev wg0
      '';
      ExecStop = with pkgs; writers.writeBash "wg-down" ''
        ${iproute2}/bin/ip -n wg route del default dev wg0 || true
        ${iproute2}/bin/ip -n wg link del wg0 || true
      '';
    };
  };


  # Bind deluged to the WireGuard network namespace
  systemd.services.deluged = {
    bindsTo = [ "netns@wg.service" ];
    requires = [ "network-online.target" "wg.service" ];
    serviceConfig.NetworkNamespacePath = [ "/var/run/netns/wg" ];
  };

  systemd.sockets."proxy-to-deluged" = {
    enable = true;
    description = "Socket for Proxy to Deluge Daemon";
    listenStreams = [ "58846" ];
    wantedBy = [ "sockets.target" ];
  };

  # Proxy service that forwards root namespace port to isolated namespace
  systemd.services."proxy-to-deluged" = {
    enable = true;
    description = "Proxy to Deluge Daemon in Network Namespace";
    requires = [ "deluged.service" "proxy-to-deluged.socket" ];
    after = [ "deluged.service" "proxy-to-deluged.socket" ];
    unitConfig = { JoinsNamespaceOf = "deluged.service"; };
    serviceConfig = {
      User = "deluge";
      Group = "deluge";
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:58846";
      PrivateNetwork = "yes";
    };
  };
}
