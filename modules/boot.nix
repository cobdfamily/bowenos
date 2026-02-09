{ lib, config, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;
  mkPath = x: if lib.hasPrefix "/dev/" x then x else "/dev/disk/by-id/" + x;

  boota = get "BOOTA_BYID" "";
  bootb = get "BOOTB_BYID" "";
  bootaPath = mkPath boota;
  bootbPath = mkPath bootb;

  diskMode = lib.attrByPath [ "bowenos" "storage" "diskMode" ] "mirror" config;
  useMirror = diskMode == "mirror";

  bootMode = get "BOOT_MODE" "uefi";
  useEfi = bootMode == "uefi";
in
{
  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = (bootMode == "uefi") || (bootMode == "bios");
          message = "BOOT_MODE must be 'uefi' or 'bios'.";
        }
        {
          assertion = (bootMode != "bios") || (boota != "");
          message = "BOOTA_BYID is required when BOOT_MODE=bios.";
        }
        {
          assertion = (!useMirror) || (bootb != "");
          message = "BOOTB_BYID is required when DISK_MODE=mirror.";
        }
      ];
    }
    (lib.mkIf useEfi {
      # GRUB on UEFI, mirrored EFI partitions.
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = true;
      boot.loader.grub.zfsSupport = true;
      boot.loader.grub.devices = [ "nodev" ];
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.efi.efiSysMountPoint = "/boot";
      boot.loader.grub.mirroredBoots = [
        { devices = [ "nodev" ]; path = "/boot"; }
        { devices = [ "nodev" ]; path = "/boot-fallback"; }
      ];
      fileSystems."/boot-fallback".options = [ "nofail" "x-systemd.device-timeout=1s" ];
    })
    (lib.mkIf (!useEfi) {
      # BIOS boot via GRUB (ZFS support enabled).
      boot.loader.grub.enable = true;
      boot.loader.grub.zfsSupport = true;
      boot.loader.grub.devices =
        (if useMirror then [ bootaPath bootbPath ] else [ bootaPath ]);
    })
  ];
}
