{ ... }:
{
  imports = [
    ../base.nix
    ../base-packages.nix
    ../users-ssh.nix
    ../networking.nix
    ../storage-tmpfs-root.nix
    ../storage-ext4.nix
    ../persistence.nix
    ../console-serial.nix
    ../boot.nix
    ../system-emergency.nix
  ];
}