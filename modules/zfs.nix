{ ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # Ensure EFI boot is configured (avoid GRUB assertion).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}