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
    ../../modules/services/nfs.nix
    ../../modules/services/iscsi.nix
  ];

  bowenos.iscsi.enable = true;

  system.stateVersion = "25.11";
}
