{ ... }:
{
  boot.supportedFilesystems = [ "ext4" "vfat" ];
  boot.initrd.supportedFilesystems = [ "ext4" "vfat" ];
}
