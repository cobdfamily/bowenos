{ ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/users-ssh.nix
    ../../modules/networking.nix
    ../../modules/storage-zfs.nix
    ../../modules/persistence.nix
    ../../hardware/server.nix
    ../../modules/boot.nix
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
