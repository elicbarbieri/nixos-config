# Home Server Configuration
{ config, pkgs, nixvim, ... }:

let
  base-packages = import ../../modules/base-packages.nix { inherit pkgs nixvim; };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./ark.nix
  ];

  # sops-nix configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/age/keys.txt";
    secrets = {
      "deluge/auth" = {
        owner = "deluge";
        group = "deluge";
        mode = "0600";
        restartUnits = [ "deluged.service" ];
      };
      "airvpn/wireguard-private-key" = {
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
        restartUnits = [ "wireguard-wg-vpn.service" ];
      };
      "ark/admin-password" = {};
      "ark/server-password" = {};
    };

  };

  # UUID: b0de9c80:a5ac423d:61f20052:ba33e57e (RAID array UUID)
  # Filesystem UUID: d9b99d85-6a26-4637-b8db-342f465b58f8
  fileSystems."/mnt/md0" = {
    device = "/dev/disk/by-uuid/d9b99d85-6a26-4637-b8db-342f465b58f8";
    fsType = "ext4";
  };

  fileSystems."/mnt/deepstor" = {
    device = "/dev/disk/by-label/deepstor";
    fsType = "ext4";
  };

  # Enable mdadm for RAID5 array management
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    ARRAY /dev/md0 UUID=b0de9c80:a5ac423d:61f20052:ba33e57e
  '';

  environment.systemPackages = base-packages.common ++ (with pkgs; [
    btrfs-progs
  ]);

  networking.hostName = "elicb-home-server";

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      58846         # Deluge daemon port
      27020 27021 27022  # ARK RCON ports (Island, Scorched, Aberration)
    ];
    allowedUDPPorts = [
      7777 7778       # ARK Island (game + query)
      7779 7780       # ARK Scorched (game + query)
      7781 7782       # ARK Aberration (game + query)
    ];
  };

  # Enable IP forwarding for VPN namespace NAT
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Additional groups for server functionality
  users.users.elicb.extraGroups = [ "docker" "deluge" "plex" ];

  users.users.elicb.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgDA8a/EFrgf2Vzr7+Qnh1UBzu/l5xX1e/vMtNs1hiwdPCfjv/MisPidTlvU5X1tUvAGUZodX871FdnNX1EfRbWxX2kvURaM0GPJRhzCI+vmohH365qix4/HDUCVCFMGwDV8J6n3SgOYoOfGTOaFt+Q1Xmw8hHQfGOdxrh2AYWsGEjOhen4lPhZVDKzUB6+ZQmFnDWS9nd7ds8YOJ6ryxgdEICaD+rPSCDaRDJy5iHM4hyNITTm50pCR+oeYZ1Ay8q5ec3XEmpFGQSw4Roz5LV95TIfb0U7In8TTPGFrIPkxsvrEhBIdAVTcJXctHC4Ei2kOCAz0ArM0qA/L/Lpu7BNb/7eNHICEekTGx7v2tPqiE8+zTU8r7P2f5jWLcVYcJX8Xmj9xzBccR8Jo21+oujwo9Z2Yae94cdDkQeSQpASi/lZo7u7X7dfmUU70pypaDJhNwJv2GGRjRUPHFxVDMkRWJTGI0+QG8MoPMneOuolfOi7oSfrJ8/BrW3SlOOFgd73pvplZ4op/EwPCNKPgsig8oh24KOPxOD3C4hOPVr5OK7TVhG0KuHGeOkUgbtdC7RBcmwXWCKbmZ6xfrxXwvtuagWp5/6d3Cu96K2Q3dhVbh/DSaJH1uMKnEW0fsuB8xXj/YI5GrpaLIFNBpIibMiwOh3EJQQCawldKBJFRN3WQ== elicb@elicb-xps-wsl"
  ];

  virtualisation.docker.enable = true;

  # Plex Media Server
  services.plex = {
    enable = true;
    openFirewall = true;  # Opens port 32400 and other Plex ports for remote access
    dataDir = "/var/lib/plex";  # Metadata, database, and transcoding cache
  };

  # Allow Plex to read media files downloaded by Deluge
  users.users.plex.extraGroups = [ "deluge" ];

  services.deluge = {
    enable = true;
    web.enable = false;
    declarative = true;
    config = {
      daemon_port = 58846;
      allow_remote = true;
      download_location = "/mnt/deepstor/media/";

      # Port forwarding (AirVPN forwarded ports: 24403-24407)
      listen_ports = [ 24403 24407 ];
      random_port = false;
      listen_interface = "0.0.0.0";
      outgoing_ports = [ 24403 24407 ];
      random_outgoing_ports = false;

      max_active_limit = -1;              # Unlimited active torrents
      max_active_downloading = 10;         # 10 downloading simultaneously
      max_active_seeding = -1;             # Unlimited seeding

      max_connections_global = 800;        # Total connections across all torrents
      max_connections_per_torrent = 100;   # Per-torrent connection limit
      max_upload_slots_global = -1;        # Unlimited global upload slots
      max_upload_slots_per_torrent = 8;    # 8 upload slots per torrent

      # Disable unnecessary features (manual port forwarding in use)
      upnp = false;                        # Disable UPnP
      natpmp = false;                      # Disable NAT-PMP

      dht = true;                          # Enable DHT
      utpex = true;                        # Enable peer exchange
      lsd = true;                          # Enable Local Service Discovery
    };
    authFile = config.sops.secrets."deluge/auth".path;
  };

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

  # Setup VPN namespace with veth pair for initial connectivity
  systemd.services."netns-vpn-setup" = {
    description = "Setup VPN network namespace with veth pair";
    after = [ "netns@vpn.service" "network-online.target" ];
    requires = [ "netns@vpn.service" "network-online.target" ];
    before = [ "wireguard-wg-vpn.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = pkgs.writeShellScript "setup-vpn-netns" ''
        set -e

        ${pkgs.iproute2}/bin/ip link del veth-host 2>/dev/null || true  # Cleanup any existing veth interfaces

        ${pkgs.iproute2}/bin/ip link add veth-vpn type veth peer name veth-host
        ${pkgs.iproute2}/bin/ip link set veth-vpn netns vpn    # Move veth-vpn into the VPN namespace

        # Configure host side
        ${pkgs.iproute2}/bin/ip addr add 10.200.200.1/24 dev veth-host
        ${pkgs.iproute2}/bin/ip link set veth-host up

        # Configure namespace side
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip addr add 10.200.200.2/24 dev veth-vpn
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip link set veth-vpn up
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip link set lo up

        # Disable IPv6 in VPN namespace to prevent leaks
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.procps}/bin/sysctl -w net.ipv6.conf.all.disable_ipv6=1
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.procps}/bin/sysctl -w net.ipv6.conf.default.disable_ipv6=1

        # Enable NAT so namespace can reach VPN server
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -j MASQUERADE
        ${pkgs.iptables}/bin/iptables -A FORWARD -i veth-host -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A FORWARD -o veth-host -j ACCEPT
      '';

      ExecStop = pkgs.writeShellScript "teardown-vpn-netns" ''
        # Cleanup NAT rules
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -j MASQUERADE 2>/dev/null || true
        ${pkgs.iptables}/bin/iptables -D FORWARD -i veth-host -j ACCEPT 2>/dev/null || true
        ${pkgs.iptables}/bin/iptables -D FORWARD -o veth-host -j ACCEPT 2>/dev/null || true

        # Delete veth pair (this also removes it from namespace)
        ${pkgs.iproute2}/bin/ip link del veth-host 2>/dev/null || true
      '';
    };
  };

  networking.wireguard.interfaces.wg-vpn = {
    ips = [ "10.140.151.141/32" ];
    mtu = 1320;
    privateKeyFile = config.sops.secrets."airvpn/wireguard-private-key".path;

    # Socket in root namespace, interface moved to VPN namespace
    socketNamespace = null;  # null = root/init namespace
    interfaceNamespace = "vpn";  # Move interface to VPN namespace

    # Don't let NixOS automatically manage routes - we do it manually for security
    allowedIPsAsRoutes = false;

    # AirVPN server configuration
    peers = [{
      publicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
      presharedKey = "yRx8sd+1PE+lh1E89dJ/HgR2kGN3pGbYwqMhpEpOM6E=";
      endpoint = "us3.vpn.airdns.org:1637";
      allowedIPs = [ "0.0.0.0/0" ];
      persistentKeepalive = 15;
    }];

    preSetup = ''
      # Cleanup any stale interface from previous failed runs
      ${pkgs.iproute2}/bin/ip link delete wg-vpn 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip link delete wg-vpn 2>/dev/null || true

      # namespace DNS configuration (AirVPN DNS)
      mkdir -p /etc/netns/vpn
      echo "nameserver 10.128.0.1" > /etc/netns/vpn/resolv.conf
      chmod 644 /etc/netns/vpn/resolv.conf

      echo "WireGuard preSetup: Cleaned up stale interfaces, DNS configured"
    '';

    postSetup = ''
      echo "=== WireGuard postSetup: Configuring killswitch ==="

      ${pkgs.iproute2}/bin/ip -n vpn route flush table main   # KILLSWITCH: Flush ALL routes in VPN namespace

      ${pkgs.iproute2}/bin/ip -n vpn route add default dev wg-vpn
      ${pkgs.iproute2}/bin/ip -n vpn route add 10.200.200.0/24 dev veth-vpn scope link  # Add veth route for proxy communication (link-local scope, no gateway)
    '';

    postShutdown = ''
      rm -rf /etc/netns/vpn
      echo "WireGuard postShutdown: Cleaned up namespace DNS config"
    '';
  };

  # Bind deluged to VPN namespace - traffic only flows through VPN tunnel
  systemd.services.deluged = {
    bindsTo = [ "netns@vpn.service" "wireguard-wg-vpn.target" ];
    requires = [ "wireguard-wg-vpn.target" ];
    after = [ "wireguard-wg-vpn.target" ];

    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
    };
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

  # Docker container backend (containers defined in ark.nix)
  virtualisation.oci-containers.backend = "docker";
}
