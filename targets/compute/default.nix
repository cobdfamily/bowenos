{ ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/base-packages.nix
    ../../modules/users-ssh.nix
    ../../modules/networking.nix
    ../../modules/storage-tmpfs-root.nix
    ../../modules/storage-zfs.nix
    ../../modules/persistence.nix
    ../../modules/console-serial.nix
    ../../modules/boot.nix
    ../../modules/system-emergency.nix
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
