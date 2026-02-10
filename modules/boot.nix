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
  imports = [ ./boot-uki.nix ];

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = bootMode == "uefi";
          message = "bootMode must be 'uefi' when using systemd-boot.";
        }
        {
          assertion = (!useMirror) || (bootb != "");
          message = "bootbById is required when diskMode=mirror.";
        }
      ];
    }
    (lib.mkIf useEfi {
      # systemd-boot on UEFI, mirrored EFI partitions.
      boot.loader.systemd-boot.enable = true;
      boot.loader.timeout = 30;            # seconds
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.efi.efiSysMountPoint = "/boot";
      fileSystems."/boot".options = [ "nofail" "x-systemd.device-timeout=1s" ];
      fileSystems."/boot-fallback".options = [ "nofail" "x-systemd.device-timeout=1s" ];
      system.activationScripts."systemd-boot-mirror".text = ''
        if ${pkgs.util-linux}/bin/mountpoint -q /boot-fallback; then
          ${pkgs.coreutils}/bin/rm -rf /boot-fallback/EFI /boot-fallback/loader
          ${pkgs.coreutils}/bin/mkdir -p /boot-fallback
          if ${pkgs.coreutils}/bin/test -d /boot/EFI; then
            ${pkgs.coreutils}/bin/cp -a /boot/EFI /boot-fallback/
          fi
          if ${pkgs.coreutils}/bin/test -d /boot/loader; then
            ${pkgs.coreutils}/bin/cp -a /boot/loader /boot-fallback/
          fi
        fi
      '';
    })
  ];
}
