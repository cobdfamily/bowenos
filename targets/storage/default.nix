{ ... }:
{
  imports = [
    ../../modules/hardware/server.nix
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
  ];

  system.stateVersion = "25.11";
}