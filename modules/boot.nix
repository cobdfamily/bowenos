{ lib, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;
  mkPath = x: if lib.hasPrefix "/dev/" x then x else "/dev/disk/by-id/" + x;

  boota = get "BOOTA_BYID" "";
  bootb = get "BOOTB_BYID" "";
  bootaPath = mkPath boota;
  bootbPath = mkPath bootb;

  diskMode = get "DISK_MODE" "mirror";
  useMirror = diskMode == "mirror";

  bootMode = get "BOOT_MODE" "uefi";
  useEfi = bootMode == "uefi";
in
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

  config = lib.mkMerge [
    (lib.mkIf useEfi {
      # Ensure EFI boot is configured.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
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
