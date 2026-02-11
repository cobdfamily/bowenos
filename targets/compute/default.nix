{ ... }:
{
  imports = [
    ../../modules/hardware/server.nix
    ../../modules/lan-bridge.nix
    ../../modules/services/incus.nix
  ];

  bowenos.incusPreseed = {
    enable = true;
    storagePoolName = "zfs-ssd";
    zfsSource = "rpool/incus";
    createDefaultNetwork = true;
    createLanProfile = true;
    lanBridgeParent = "br0";
    lanProfileName = "bridge-to-lan";
  };

  bowenos.lanBridge = {
    enable = true;
    bridgeName = "br0";
  };

  system.stateVersion = "25.11";
}
