{ ... }:
{
  imports = [
    ../../modules/identity.nix
    ../../modules/users-ssh.nix
    ../../modules/networking.nix
    ../../modules/zfs.nix
    ../../modules/impermanence.nix
    ../../modules/serial-console.nix
    ../../modules/boot-efi.nix
    ../../modules/efi-mirror.nix
    ../../modules/lan-bridge.nix
    ../../modules/incus-preseed.nix
    ../../modules/nfs.nix
    ../../modules/iscsi/module.nix
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

  bowenos.efiMirror = {
    enable = true;
    mirrorMount = "/boot-mirror";
    bootLabel = "NixOS (mirror)";
  };

  bowenos.iscsi.enable = true;

  system.stateVersion = "25.11";
}
