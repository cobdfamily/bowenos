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
    ../../modules/efi-mirror.nix
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

  # EFI mirror uses BOOTB_BYID by default; override if needed:
  # BOOTB_DISK_PATH=/dev/disk/by-id/<BOOTB_BYID>
  bowenos.efiMirror = {
    enable = true;
    mirrorMount = "/boot-mirror";
    bootLabel = "NixOS (mirror)";
  };

  system.stateVersion = "25.11";
}
