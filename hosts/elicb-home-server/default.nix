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

  # sops-nix configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/elicb/.config/sops/age/keys.txt";
    secrets = {
      "nordvpn/username" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
      "nordvpn/password" = {
        owner = "root";
        group = "root";
        mode = "0400";
        restartUnits = [ "openvpn-nordvpn.service" ];
      };
    };
  };

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

  # Install base packages + btrfs tools + VPN utilities
  environment.systemPackages = base-packages.common ++ (with pkgs; [
    btrfs-progs
  ]);

  # Host-specific configuration
  networking.hostName = "elicb-home-server";

  # Enable IP forwarding for VPN namespace NAT
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

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
    before = [ "openvpn-nordvpn.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = pkgs.writeShellScript "setup-vpn-netns" ''
        set -e

        # Create veth pair to connect namespace to host
        ${pkgs.iproute2}/bin/ip link add veth-vpn type veth peer name veth-host

        # Move veth-vpn into the VPN namespace
        ${pkgs.iproute2}/bin/ip link set veth-vpn netns vpn

        # Configure host side
        ${pkgs.iproute2}/bin/ip addr add 10.200.200.1/24 dev veth-host
        ${pkgs.iproute2}/bin/ip link set veth-host up

        # Configure namespace side
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip addr add 10.200.200.2/24 dev veth-vpn
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip link set veth-vpn up
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip link set lo up

        # Add default route through veth pair (only for establishing VPN connection)
        ${pkgs.iproute2}/bin/ip netns exec vpn ${pkgs.iproute2}/bin/ip route add default via 10.200.200.1

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

  # Prepare OpenVPN configuration and credentials
  systemd.services."openvpn-nordvpn-prepare" = {
    description = "Prepare NordVPN OpenVPN configuration";
    before = [ "openvpn-nordvpn.service" ];
    requires = [ "netns@vpn.service" "network-online.target" ];
    after = [ "netns@vpn.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = pkgs.writeShellScript "prepare-nordvpn-config" ''
        set -e

        # Create runtime directory
        mkdir -p /run/openvpn-nordvpn
        chmod 700 /run/openvpn-nordvpn

        # Create namespace-specific resolv.conf directory
        mkdir -p /etc/netns/vpn
        echo "nameserver 103.86.96.100" > /etc/netns/vpn/resolv.conf  # NordVPN DNS
        echo "nameserver 103.86.99.100" >> /etc/netns/vpn/resolv.conf  # NordVPN DNS backup

        # Download NordVPN config (using us9863 server - change as needed)
        ${pkgs.curl}/bin/curl -sf https://downloads.nordcdn.com/configs/files/ovpn_udp/servers/us9863.nordvpn.com.udp.ovpn \
          -o /run/openvpn-nordvpn/config.ovpn

        # Create auth file with proper format (username on line 1, password on line 2)
        # Ensure proper newlines by using echo to strip and re-add them
        echo "$(cat ${config.sops.secrets."nordvpn/username".path})" > /run/openvpn-nordvpn/auth.txt
        echo "$(cat ${config.sops.secrets."nordvpn/password".path})" >> /run/openvpn-nordvpn/auth.txt
        chmod 600 /run/openvpn-nordvpn/auth.txt

        # Create the killswitch up script
        # This runs AFTER OpenVPN establishes the tunnel and deletes all non-VPN routes
        cat > /run/openvpn-nordvpn/up-script.sh <<'EOF'
#!/bin/sh
# KILLSWITCH: Delete ALL routes except the VPN tunnel routes
# After this runs, ONLY tun0 routes exist - if VPN fails, NO internet access

echo "Routes before killswitch activation:"
${pkgs.iproute2}/bin/ip route

# Delete all routes that are NOT via tun0
# This iteratively removes non-tun0 routes until only tun0 routes remain
while ${pkgs.iproute2}/bin/ip route show | grep -v 'dev tun0' | grep -v '^$' > /dev/null; do
  # Get the first non-tun0 route
  ROUTE=$(${pkgs.iproute2}/bin/ip route show | grep -v 'dev tun0' | head -n1)

  if [ -n "$ROUTE" ]; then
    echo "Deleting route: $ROUTE"
    ${pkgs.iproute2}/bin/ip route del $ROUTE 2>/dev/null || true
  else
    break
  fi
done

echo ""
echo "KILLSWITCH ACTIVATED: All non-VPN routes deleted"
echo "Remaining routes (tun0 only):"
${pkgs.iproute2}/bin/ip route
EOF
        chmod +x /run/openvpn-nordvpn/up-script.sh

        # Add auth-user-pass directive to config
        echo "auth-user-pass /run/openvpn-nordvpn/auth.txt" >> /run/openvpn-nordvpn/config.ovpn

        # Add up script to run after tunnel is established
        echo "script-security 2" >> /run/openvpn-nordvpn/config.ovpn
        echo "up /run/openvpn-nordvpn/up-script.sh" >> /run/openvpn-nordvpn/config.ovpn

        # Disable DNS updates in config since we handle it ourselves
        echo "pull-filter ignore \"dhcp-option DNS\"" >> /run/openvpn-nordvpn/config.ovpn
      '';

      ExecStop = pkgs.writeShellScript "cleanup-nordvpn-config" ''
        rm -rf /run/openvpn-nordvpn
        rm -rf /etc/netns/vpn
      '';
    };
  };

  # Configure OpenVPN to run in VPN namespace using NixOS service
  services.openvpn.servers.nordvpn = {
    config = ''
      config /run/openvpn-nordvpn/config.ovpn
    '';
    autoStart = true;
  };

  # Bind OpenVPN service to VPN namespace - this is the killswitch!
  systemd.services.openvpn-nordvpn = {
    after = [ "netns@vpn.service" "netns-vpn-setup.service" "openvpn-nordvpn-prepare.service" ];
    requires = [ "netns@vpn.service" "netns-vpn-setup.service" "openvpn-nordvpn-prepare.service" ];
    bindsTo = [ "netns@vpn.service" ];

    serviceConfig = {
      # THIS IS THE KILLSWITCH: The service runs in an isolated network namespace
      NetworkNamespacePath = "/var/run/netns/vpn";

      # Ensure proper restart behavior
      Restart = "always";
      RestartSec = "10s";
    };
  };

  # Bind deluged to the VPN network namespace - KILLSWITCH ENABLED
  # Deluge will ONLY be able to access internet through the VPN tunnel
  # If VPN drops, deluge has no route out - 100% leak protection
  systemd.services.deluged = {
    bindsTo = [ "netns@vpn.service" "openvpn-nordvpn.service" ];
    requires = [ "openvpn-nordvpn.service" ];
    after = [ "openvpn-nordvpn.service" ];

    serviceConfig = {
      # THIS IS THE KILLSWITCH: Run in isolated namespace with only VPN route
      NetworkNamespacePath = "/var/run/netns/vpn";

      # Wait a bit after VPN comes up for routing to stabilize
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
}
