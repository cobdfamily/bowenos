{ lib, ... }:
{
  imports = [
    ../../modules/hardware/vm.nix
    ../../modules/services/docker.nix
    ../../modules/services/docker-compose.nix
  ];

  bowenos.storage.diskMode = lib.mkDefault "single";

  # Spine does not use lan-bridge; request DHCP on all physical Ethernet links.
  networking.useDHCP = lib.mkForce true;
  systemd.network.networks."10-spine-uplink-dhcp" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
  };
  systemd.network.wait-online.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
