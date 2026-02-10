{ lib, config, pkgs, ... }:
let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;
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
      boot.uki.tries = 3;
      fileSystems."/boot".options = [ "nofail" "x-systemd.device-timeout=1s" ];
      fileSystems."/boot-fallback".options = [ "nofail" "x-systemd.device-timeout=1s" ];
      boot.loader.systemd-boot.extraEntries = {
        "nixos-uki.conf" = ''
          title NixOS (UKI)
          efi /EFI/Linux/${config.system.boot.loader.ukiFile}
        '';
      };
      system.activationScripts."systemd-boot-uki".text = ''
        set -euo pipefail
        uki_file="${config.system.boot.loader.ukiFile}"
        ${pkgs.coreutils}/bin/mkdir -p /boot/EFI/Linux
        ${pkgs.systemdUkify}/lib/systemd/ukify build \
          --output "/boot/EFI/Linux/$uki_file" \
          --linux "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}" \
          --initrd "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}" \
          --cmdline "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}" \
          --os-release "@${config.system.build.etc}/etc/os-release" \
          --uname "${config.boot.kernelPackages.kernel.modDirVersion}" \
          --stub "${pkgs.systemd}/lib/systemd/boot/efi/linux${efiArch}.efi.stub"
        ${pkgs.gnused}/bin/sed -i "s/^default .*/default nixos-uki.conf/" /boot/loader/loader.conf
        ${lib.optionalString useMirror ''
        if ${pkgs.util-linux}/bin/mountpoint -q /boot-fallback; then
          ${pkgs.coreutils}/bin/mkdir -p /boot-fallback/EFI/Linux
          ${pkgs.coreutils}/bin/cp -f "/boot/EFI/Linux/$uki_file" "/boot-fallback/EFI/Linux/$uki_file"
        fi
        ''}
      '';
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
