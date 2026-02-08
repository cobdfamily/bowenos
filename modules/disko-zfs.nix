{ lib, config, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;

  boota = get "BOOTA_BYID" "";
  bootb = get "BOOTB_BYID" "";

  mkPath = x: if lib.hasPrefix "/dev/" x then x else "/dev/disk/by-id/" + x;

  bootaPath = mkPath boota;
  bootbPath = mkPath bootb;

  # Disk mode: mirror (default) or single (set by hardware profile)
  diskMode = config.bowenos.storage.diskMode;
  useMirror = diskMode == "mirror";

  # Boot mode: uefi (default) or bios
  bootMode = get "BOOT_MODE" "uefi";
  useEfi = bootMode == "uefi";

  espPartition = {
    size = "512M";
    type = "EF00";
    content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
  };

  espMirrorPartition = {
    size = "512M";
    type = "EF00";
    content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot-mirror"; };
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
    { assertion = boota != ""; message = "BOOTA_BYID is required (set in .env or env)."; }
    {
      assertion = (!useMirror) || bootb != "";
      message = "BOOTB_BYID is required when DISK_MODE=mirror.";
    }
    {
      assertion = (!useMirror) || (bootaPath != bootbPath);
      message = "BOOTA_BYID and BOOTB_BYID must be different disks when DISK_MODE=mirror.";
    }
    {
      assertion = (bootMode == "uefi") || (bootMode == "bios");
      message = "BOOT_MODE must be 'uefi' or 'bios'.";
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
