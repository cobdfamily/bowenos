{ lib, config, pkgs, ... }:
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
          assertion = (!useMirror) || (bootb != "");
          message = "bootbById is required when diskMode=mirror.";
        }
        {
          assertion = (bootMode == "uefi") || (bootMode == "bios");
          message = "bootMode must be 'uefi' or 'bios'.";
        }
      ];
    }

    (lib.mkIf useEfi {
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = true;
      boot.loader.grub.device = "nodev";
      boot.loader.grub.efiSysMountPoint = "/boot";
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.grub.efiInstallAsRemovable = useMirror;
      boot.loader.systemd-boot.enable = false;

      fileSystems."/boot".options = [ "nofail" "x-systemd.device-timeout=1s" ];
      fileSystems."/boot-fallback".options = [ "nofail" "x-systemd.device-timeout=1s" ];

      system.activationScripts."grub-efi-mirror".text = ''
        if ${pkgs.util-linux}/bin/mountpoint -q /boot-fallback; then
          ${pkgs.coreutils}/bin/mkdir -p /boot-fallback
          if ${pkgs.coreutils}/bin/test -d /boot/EFI; then
            ${pkgs.coreutils}/bin/rm -rf /boot-fallback/EFI
            ${pkgs.coreutils}/bin/cp -a /boot/EFI /boot-fallback/
          fi
          if ${pkgs.coreutils}/bin/test -d /boot/grub; then
            ${pkgs.coreutils}/bin/rm -rf /boot-fallback/grub
            ${pkgs.coreutils}/bin/cp -a /boot/grub /boot-fallback/
          fi
        fi
      '';
    })

    (lib.mkIf (!useEfi) {
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = false;
      boot.loader.systemd-boot.enable = false;
      boot.loader.grub.devices = if useMirror then [ bootaPath bootbPath ] else [ bootaPath ];
    })
  ];
}
