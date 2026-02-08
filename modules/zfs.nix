{ ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  boot.zfs.forceImportRoot = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

}
