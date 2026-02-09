{ ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/base-packages.nix
    ../../modules/users-ssh.nix
    ../../modules/networking.nix
    ../../modules/storage-zfs.nix
    ../../modules/persistence.nix
    ../../hardware/server.nix
    ../../modules/boot.nix
    ../../modules/lan-bridge.nix
    ../../modules/services/incus.nix
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
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

  bowenos.iscsi.enable = true;

  system.stateVersion = "25.11";
}
