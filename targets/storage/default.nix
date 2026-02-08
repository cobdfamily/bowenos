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
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
  ];

  bowenos.efiMirror = {
    enable = true;
    mirrorMount = "/boot-mirror";
    bootLabel = "NixOS (mirror)";
  };

  bowenos.iscsi.enable = true;

  system.stateVersion = "25.11";
}
