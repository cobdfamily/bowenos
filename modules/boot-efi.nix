{ ... }:
{
  # Ensure EFI boot is configured (avoid GRUB assertion).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
