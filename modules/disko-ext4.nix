{ lib, config ? {}, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;

  bootaCfg = lib.attrByPath [ "bowenos" "storage" "bootaById" ] "" config;
  boota = if bootaCfg != "" then bootaCfg else get "BOOTA_BYID" "";
  bootaPath = if lib.hasPrefix "/dev/" boota then boota else "/dev/disk/by-id/" + boota;
  persistPath = "/dev/sdb";

  diskModeCfg = lib.attrByPath [ "bowenos" "storage" "diskMode" ] "" config;
  diskMode = if diskModeCfg != "" then diskModeCfg else
    (let v = get "DISK_MODE" ""; in if v == "" then "mirror" else v);

  bootModeCfg = lib.attrByPath [ "bowenos" "storage" "bootMode" ] "" config;
  bootMode = if bootModeCfg != "" then bootModeCfg else
    (let v = get "BOOT_MODE" ""; in if v == "" then "uefi" else v);
  useEfi = bootMode == "uefi";

  espPartition = {
    size = "512M";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot";
      mountOptions = [ "nofail" "x-systemd.device-timeout=1s" ];
    };
  };

  biosBootPartition = {
    size = "1M";
    type = "EF02";
  };

  nixPartition = {
    size = "100%";
    content = {
      type = "filesystem";
      format = "ext4";
      mountpoint = "/nix";
      mountOptions = [ "defaults" ];
    };
  };

  persistPartition = {
    size = "100%";
    content = {
      type = "filesystem";
      format = "ext4";
      mountpoint = "/persist";
      mountOptions = [ "defaults" ];
    };
  };
in
{
  assertions = [
    { assertion = boota != ""; message = "bootaById is required in host local.nix."; }
    {
      assertion = diskMode == "single";
      message = "spine ext4 layout currently supports diskMode=single only.";
    }
    {
      assertion = (bootMode == "uefi") || (bootMode == "bios");
      message = "bootMode must be 'uefi' or 'bios'.";
    }
  ];

  disko.devices = {
    disk = {
      bootA = {
        type = "disk";
        device = bootaPath;
        content = {
          type = "gpt";
          partitions =
            (lib.optionalAttrs useEfi { esp = espPartition; })
            // (lib.optionalAttrs (!useEfi) { bios = biosBootPartition; })
            // { nix = nixPartition; };
        };
      };

      persist = {
        type = "disk";
        device = persistPath;
        content = {
          type = "gpt";
          partitions = {
            persist = persistPartition;
          };
        };
      };
    };
  };
}
