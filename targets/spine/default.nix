{ lib, ... }:
{
  imports = [
    ../../modules/hardware/vm.nix
    ../../modules/services/docker.nix
    ../../modules/services/docker-compose.nix
  ];

  bowenos.storage.diskMode = lib.mkDefault "single";

  system.stateVersion = "25.11";
}