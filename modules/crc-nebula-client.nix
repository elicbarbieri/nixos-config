# CRC-over-Nebula client (mesh-peer side)
#
# Counterpart to `specializations/crc-nebula-exposure.nix`, which runs on the
# CRC host and DNATs mesh traffic on 6443/80/443 to the CRC node. Imported only
# by a host's `kubernetes` specialisation, so none of this is active on a normal
# boot — it exists purely for cluster-dev sessions.
#
# Resolving the real `*.crc.testing` / `*.apps-crc.testing` names to the CRC
# host's Nebula IP lets `oc`, `docker` and the ztest engine reach the API,
# OAuth, ingress and image-registry routes by hostname, so TLS verifies against
# the CRC-issued certs (no --insecure, no tls-server-name shims) and `oc login`'s
# OAuth redirect resolves.
{ lib, ... }:

let
  crcNebulaIp = "100.64.0.3"; # elicb-dell-desktop on the mesh
  registryHost = "default-route-openshift-image-registry.apps-crc.testing";
in
{
  # `address=` synthesizes the A record locally: the Nebula DNAT forwards only
  # 6443/80/443, so there is no resolver at the Nebula IP to `server=`-forward to.
  networking.networkmanager.dns = "dnsmasq";
  environment.etc."NetworkManager/dnsmasq.d/crc-nebula-client.conf".text = ''
    address=/crc.testing/${crcNebulaIp}
    address=/apps-crc.testing/${crcNebulaIp}
  '';

  # The registry Route serves a cert from the cluster ingress CA, which the host
  # Docker daemon doesn't trust. Over the already-encrypted mesh, allow it as an
  # insecure registry rather than installing the ingress CA into docker's trust.
  virtualisation.docker.daemon.settings.insecure-registries = [ "${registryHost}" ];
}
