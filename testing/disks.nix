{ lib, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;

  diskA = get "BOOTA_BYID" "";
  diskB = get "BOOTB_BYID" "";
  mkPath = x: if lib.hasPrefix "/dev/" x then x else "/dev/disk/by-id/" + x;
in
{
  assertions = [
    { assertion = diskA != ""; message = "BOOTA_BYID is required."; }
    { assertion = diskB != ""; message = "BOOTB_BYID is required."; }
  ];

  disko.devices = {
    disk = {
      bootA = {
        type = "disk";
        device = mkPath diskA;
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
        device = mkPath diskB;
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "512M";
              type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot-fallback"; };
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
      postCreateHook = ''
        zpool set bootfs=rpool/root rpool
      '';

      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
        normalization = "formD";
        canmount = "off";
        mountpoint = "none";
      };

      datasets = {
        root = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
        };
        persist = {
          type = "zfs_fs";
          mountpoint = "/persist";
          options.mountpoint = "legacy";
        };
      };
    };
  };
}
