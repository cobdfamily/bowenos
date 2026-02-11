{ lib, config, pkgs, ... }:
let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;
  diskMode = lib.attrByPath [ "bowenos" "storage" "diskMode" ] "mirror" config;
  useMirror = diskMode == "mirror";
in
{
  config = lib.mkIf config.boot.loader.systemd-boot.enable {
    boot.uki.tries = 3;

    boot.loader.systemd-boot.extraEntries = {
      "nixos-uki.conf" = ''
        title NixOS (UKI)
        efi /EFI/Linux/${config.system.boot.loader.ukiFile}
      '';
    };

    # Build and install the UKI at activation time to avoid build-time recursion.
    system.activationScripts."systemd-boot-uki".text = ''
      set -euo pipefail
      uki_file="${config.system.boot.loader.ukiFile}"
      ${pkgs.coreutils}/bin/mkdir -p /boot/EFI/Linux
      ${pkgs.coreutils}/bin/mkdir -p /boot/loader
      if [ ! -f /boot/loader/loader.conf ]; then
        ${pkgs.coreutils}/bin/printf "default nixos\n" > /boot/loader/loader.conf
      fi
      ${pkgs.systemdUkify}/lib/systemd/ukify build \
        --output "/boot/EFI/Linux/$uki_file" \
        --linux "$systemConfig/kernel" \
        --initrd "$systemConfig/initrd" \
        --cmdline "init=$systemConfig/init ${toString config.boot.kernelParams}" \
        --os-release "@$systemConfig/etc/os-release" \
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
  };
}
