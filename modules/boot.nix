{ lib, config, ... }:
let
  mkPath = x: if lib.hasPrefix "/dev/" x then x else "/dev/disk/by-id/" + x;

  boota = lib.attrByPath [ "bowenos" "storage" "bootaById" ] "" config;
  bootb = lib.attrByPath [ "bowenos" "storage" "bootbById" ] "" config;
  bootaPath = mkPath boota;
  bootbPath = mkPath bootb;

  diskMode = lib.attrByPath [ "bowenos" "storage" "diskMode" ] "mirror" config;
  useMirror = diskMode == "mirror";

  bootMode = lib.attrByPath [ "bowenos" "storage" "bootMode" ] "uefi" config;
  useEfi = bootMode == "uefi";
in
{
  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = (bootMode == "uefi") || (bootMode == "bios");
          message = "bootMode must be 'uefi' or 'bios'.";
        }
        {
          assertion = (bootMode != "bios") || (boota != "");
          message = "bootaById is required when bootMode=bios.";
        }
        {
          assertion = (!useMirror) || (bootb != "");
          message = "bootbById is required when diskMode=mirror.";
        }
      ];
    }
    (lib.mkIf useEfi {
      # GRUB on UEFI, mirrored EFI partitions.
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = true;
      boot.loader.grub.zfsSupport = true;
      boot.loader.grub.devices = [ "nodev" ];
      boot.loader.grub.timeoutStyle = "menu";  # ALWAYS show menu
      boot.loadertimeout = 30;            # seconds
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
