{ ... }:
{
  imports = [
    ../../modules/hardware/server.nix
    ../../modules/lan-bridge.nix
    ../../modules/services/incus.nix
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
  ];

  bowenos.lanBridge = {
    enable = true;
    bridgeName = "br0";
  };

  bowenos.iscsi.enable = true;

  system.stateVersion = "25.11";
}
