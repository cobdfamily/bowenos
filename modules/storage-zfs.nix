{ config, ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.initrd.preDeviceCommands = ''
    udevadm settle --timeout=10 || true
    sleep 2
  '';
  boot.zfs.devNodes = if config.bowenos.storage.isVm then "/dev/disk/by-path" else "/dev/disk/by-id";
  boot.zfs.extraPools = [ "rpool" ];
  boot.zfs.forceImportRoot = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

}
