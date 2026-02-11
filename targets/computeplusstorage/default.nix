{ ... }:
{
  imports = [
    ../../modules/hardware/server.nix
    ../../modules/lan-bridge.nix
    ../../modules/services/incus.nix
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
  ];

  system.stateVersion = "25.11";
}