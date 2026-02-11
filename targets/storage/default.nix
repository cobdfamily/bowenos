{ ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/base-packages.nix
    ../../modules/users-ssh.nix
    ../../modules/networking.nix
    ../../modules/storage-root-tmpfs.nix
    ../../modules/storage-zfs.nix
    ../../modules/persistence.nix
    ../../modules/console-serial.nix
    ../../modules/boot.nix
    ../../modules/system-emergency.nix
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
  ];

  bowenos.iscsi.enable = true;

  system.stateVersion = "25.11";
}