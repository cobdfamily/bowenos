{ config, ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = if config.bowenos.storage.isVm then "/dev/disk/by-path" else "/dev/disk/by-id";
  boot.zfs.extraPools = [ "rpool" ];
  boot.zfs.forceImportRoot = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  fileSystems."/" = { device = "rpool/root"; fsType = "zfs"; };
  fileSystems."/nix" = { device = "rpool/nix"; fsType = "zfs"; };
  fileSystems."/persist" = { device = "rpool/persist"; fsType = "zfs"; };

}
