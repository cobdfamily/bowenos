{ lib, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;

  boota = get "BOOTA_BYID" "";
  bootb = get "BOOTB_BYID" "";

  mkPath = x: if lib.hasPrefix "/dev/" x then x else "/dev/disk/by-id/" + x;
in
{
  assertions = [
    { assertion = boota != ""; message = "BOOTA_BYID is required (set in .env or env)."; }
    { assertion = bootb != ""; message = "BOOTB_BYID is required (set in .env or env)."; }
  ];

  disko.devices = {
    disk = {
      bootA = {
        type = "disk";
        device = mkPath boota;
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "512M";
              type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
            };
            zfs = { size = "100%"; content = { type = "zfs"; pool = "rpool"; }; };
          };
        };
      };

      bootB = {
        type = "disk";
        device = mkPath bootb;
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "512M";
              type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot-mirror"; };
            };
            zfs = { size = "100%"; content = { type = "zfs"; pool = "rpool"; }; };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      mode = "mirror";
      options = { ashift = "12"; autotrim = "on"; };

      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
        normalization = "formD";
      };

      datasets = {
        root = { type = "zfs_fs"; mountpoint = "/"; };
        nix = { type = "zfs_fs"; mountpoint = "/nix"; };
        persist = { type = "zfs_fs"; mountpoint = "/persist"; };
        incus = { type = "zfs_fs"; mountpoint = "/rpool-incus"; };
      };
    };
  };
}