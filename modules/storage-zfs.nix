{ lib, config, pkgs, ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.initrd.preDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
    udevadm settle --timeout=10 || true
    sleep 2
  '';
  boot.initrd.systemd.services.zfs-udev-settle = lib.mkIf config.boot.initrd.systemd.enable {
    description = "Wait for udev and disks before ZFS import";
    wantedBy = [ "initrd.target" ];
    before = [ "zfs-import.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.systemd}/bin/udevadm settle --timeout=10"
        "${pkgs.coreutils}/bin/sleep 2"
      ];
    };
  };
  boot.zfs.devNodes = if config.bowenos.storage.isVm then "/dev/disk/by-path" else "/dev/disk/by-id";
  boot.zfs.extraPools = [ "rpool" ];
  boot.zfs.forceImportRoot = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

}