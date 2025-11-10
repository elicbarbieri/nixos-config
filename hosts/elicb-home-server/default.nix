# Home Server Configuration
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Host-specific configuration
  networking.hostName = "elicb-home-server";

  # Additional groups for server functionality
  users.users.elicb.extraGroups = [ "docker" "deluge" ];

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
