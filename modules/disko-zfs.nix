{ lib, config ? {}, ... }:
let
  boota = lib.attrByPath [ "bowenos" "storage" "bootaById" ] "" config;
  bootb = lib.attrByPath [ "bowenos" "storage" "bootbById" ] "" config;

  mkPath = x: if lib.hasPrefix "/dev/" x then x else "/dev/disk/by-id/" + x;

  bootaPath = mkPath boota;
  bootbPath = mkPath bootb;

  # Disk mode: mirror (default) or single (set by hardware profile)
  diskMode = lib.attrByPath [ "bowenos" "storage" "diskMode" ] "mirror" config;
  useMirror = diskMode == "mirror";

  # Boot mode: uefi (default) or bios
  bootMode = lib.attrByPath [ "bowenos" "storage" "bootMode" ] "uefi" config;
  useEfi = bootMode == "uefi";

  espPartition = {
    size = "512M";
    type = "EF00";
    content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
  };

  espMirrorPartition = {
    size = "512M";
    type = "EF00";
    content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot-fallback"; };
  };

  biosBootPartition = {
    size = "1M";
    type = "EF02";
  };

  diskA = {
    type = "disk";
    device = bootaPath;
    content = {
      type = "gpt";
      partitions =
        (lib.optionalAttrs useEfi { esp = espPartition; })
        // (lib.optionalAttrs (!useEfi) { bios = biosBootPartition; })
        // { zfs = { size = "100%"; content = { type = "zfs"; pool = "rpool"; }; }; };
    };
  };

  diskB = {
    type = "disk";
    device = bootbPath;
    content = {
      type = "gpt";
      partitions =
        (lib.optionalAttrs useEfi { esp = espMirrorPartition; })
        // (lib.optionalAttrs (!useEfi) { bios = biosBootPartition; })
        // { zfs = { size = "100%"; content = { type = "zfs"; pool = "rpool"; }; }; };
    };
  };
in
{
  assertions = [
    { assertion = boota != ""; message = "bootaById is required in host local.nix."; }
    {
      assertion = (!useMirror) || bootb != "";
      message = "bootbById is required when diskMode=mirror.";
    }
    {
      assertion = (!useMirror) || (bootaPath != bootbPath);
      message = "bootaById and bootbById must be different disks when diskMode=mirror.";
    }
    {
      assertion = (bootMode == "uefi") || (bootMode == "bios");
      message = "bootMode must be 'uefi' or 'bios'.";
    }
  ];

  disko.devices = {
    disk = {
      bootA = diskA;
    } // (lib.optionalAttrs useMirror { bootB = diskB; });

    zpool.rpool = {
      type = "zpool";
      mode = if useMirror then "mirror" else "single";
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
        incus = { type = "zfs_fs"; mountpoint = "/rpool-incus"; };
      };
    };
  };
}
