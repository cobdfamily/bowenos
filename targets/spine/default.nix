{ lib, ... }:
{
  imports = [
    ../../modules/hardware/vm.nix
    ../../modules/services/docker.nix
    ../../modules/services/docker-compose.nix
  ];

  bowenos.storage.diskMode = lib.mkDefault "single";

  # Spine does not use lan-bridge; request DHCP directly on common NIC names.
  systemd.network.networks."10-spine-en-dhcp" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };
  systemd.network.networks."10-spine-eth-dhcp" = {
    matchConfig.Name = "eth*";
    networkConfig.DHCP = "yes";
  };
  systemd.network.wait-online.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
