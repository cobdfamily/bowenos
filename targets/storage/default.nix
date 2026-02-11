{ ... }:
{
  imports = [
    ../../modules/hardware/server.nix
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
  ];

  bowenos.iscsi.enable = true;

  system.stateVersion = "25.11";
}
