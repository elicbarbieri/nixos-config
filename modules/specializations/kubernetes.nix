# Kubernetes Specialization
# Enables k3s and related services for container orchestration

{ config, pkgs, lib, ... }:

{
  # Kubernetes (k3s)
  services.k3s = {
    enable = true;
    role = "server";
  };
  
  # Kubernetes-specific firewall rules
  networking.firewall = {
    trustedInterfaces = [ "cni+" ]; # Kubernetes CNI interfaces
    allowedTCPPorts = [ 
      6443  # Kubernetes API server
      10250 # Kubelet API
    ];
    allowedUDPPorts = [ 
      8472  # Flannel VXLAN
    ];
  };
}
