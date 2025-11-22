# Kubernetes Specialization
# Enables k3s and related services for container orchestration

{ config, pkgs, lib, ... }:

{
  # Load required kernel modules for k3s networking
  boot.kernelModules = [
    "overlay"           # Container overlay filesystem
    "br_netfilter"      # Bridge netfilter
    "nf_conntrack"      # Connection tracking
    "ip_tables"         # iptables support
    "iptable_nat"       # NAT table for iptables
    "iptable_filter"    # Filter table for iptables
  ];

  # Enable IP forwarding and bridge netfilter for Kubernetes
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.ipv4.ip_forward" = 1;
  };

  # Kubernetes (k3s)
  services.k3s = {
    enable = true;
    role = "server";

    # Disable embedded network policy controller to prevent race condition
    # where it tries to initialize before flannel creates its interface
    extraFlags = toString [
      "--disable-network-policy"  # Disable Calico network policy
      "--flannel-backend=vxlan"   # Explicitly set flannel backend
    ];
  };

  # Kubernetes-specific firewall rules
  networking.firewall = {
    trustedInterfaces = [
      "cni+"       # Kubernetes CNI interfaces
      "flannel.1"  # Flannel VXLAN interface
    ];
    allowedTCPPorts = [
      6443   # Kubernetes API server
      10250  # Kubelet API
    ];
    allowedUDPPorts = [
      8472   # Flannel VXLAN
    ];
  };

}
