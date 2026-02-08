{ ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  boot.zfs.extraPools = [ "rpool" ];
  boot.zfs.forceImportRoot = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.extraUnits."zfs-import.service".wantedBy = [ "initrd.target" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

}
