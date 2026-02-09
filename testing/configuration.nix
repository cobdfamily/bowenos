{ config, pkgs, lib, ... }:
{
  networking.hostName = "testing";
  networking.hostId = "deadbeef";

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = true;
  boot.zfs.extraPools = [ "rpool" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  # GRUB on UEFI with mirrored EFI partitions.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.copyKernels = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.grub.mirroredBoots = [
    { devices = [ "nodev" ]; path = "/boot"; }
    { devices = [ "nodev" ]; path = "/boot-fallback"; }
  ];

  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200n8"
  ];

  # Mirror EFI mount should not block boot if missing.
  fileSystems."/boot-fallback".options = [ "nofail" "x-systemd.device-timeout=1s" ];

  # Legacy ZFS root (matches tutorial style).
  fileSystems."/" = {
    device = "rpool/root";
    fsType = "zfs";
  };

  # Example EFI mounts (replace UUIDs).
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/EFI_PRIMARY_UUID";
    fsType = "vfat";
  };

  fileSystems."/boot-fallback" = {
    device = "/dev/disk/by-uuid/EFI_MIRROR_UUID";
    fsType = "vfat";
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... your@key" ];
  };

  security.sudo.wheelNeedsPassword = true;

  system.stateVersion = "25.11";
}
