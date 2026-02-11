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
      boot.loader.grub.efiSysMountPoint = "/bootA";
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.grub.efiInstallAsRemovable = useMirror;
      boot.loader.systemd-boot.enable = false;
      boot.loader.grub.extraConfig = ''
        if [ -s $prefix/grubenv ]; then
          load_env
        fi
        if [ "${recordfail}" = 1 ]; then
          if [ -n "${last_successful}" ]; then
            set default="${last_successful}"
          fi
        fi
      '';

      fileSystems."/bootA".options = [ "nofail" "x-systemd.device-timeout=1s" ];
      fileSystems."/bootB".options = [ "nofail" "x-systemd.device-timeout=1s" ];

      system.activationScripts."grub-efi-mirror".text = ''
        if ${pkgs.util-linux}/bin/mountpoint -q /bootB; then
          ${pkgs.coreutils}/bin/mkdir -p /bootB
          if ${pkgs.coreutils}/bin/test -d /bootA/EFI; then
            ${pkgs.coreutils}/bin/rm -rf /bootB/EFI
            ${pkgs.coreutils}/bin/cp -a /bootA/EFI /bootB/
          fi
          if ${pkgs.coreutils}/bin/test -d /bootA/grub; then
            ${pkgs.coreutils}/bin/rm -rf /bootB/grub
            ${pkgs.coreutils}/bin/cp -a /bootA/grub /bootB/
          fi
        fi
      '';
    })

    (lib.mkIf (!useEfi) {
      boot.loader.grub.enable = true;
      boot.loader.grub.efiSupport = false;
      boot.loader.systemd-boot.enable = false;
      boot.loader.grub.extraConfig = ''
        if [ -s $prefix/grubenv ]; then
          load_env
        fi
        if [ "${recordfail}" = 1 ]; then
          if [ -n "${last_successful}" ]; then
            set default="${last_successful}"
          fi
        fi
      '';
      boot.loader.grub.devices = if useMirror then [ bootaPath bootbPath ] else [ bootaPath ];
    })

    {
      systemd.services.grub-boot-success = {
        description = "Record GRUB last successful boot";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" "local-fs.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail

          grub_cfg="/boot/grub/grub.cfg"
          grub_env="/boot/grub/grubenv"
          if [ -f /bootA/grub/grub.cfg ]; then
            grub_cfg="/bootA/grub/grub.cfg"
            grub_env="/bootA/grub/grubenv"
          fi

          if [ ! -f "$grub_cfg" ]; then
            echo "grub-boot-success: grub.cfg not found at $grub_cfg" >&2
            exit 0
          fi

          booted_kernel="$(readlink -f /run/booted-system/kernel || true)"
          if [ -z "$booted_kernel" ]; then
            echo "grub-boot-success: booted kernel not found" >&2
            exit 0
          fi

          entry_id="$(
            ${pkgs.gawk}/bin/awk -v k="$booted_kernel" '
              $1 == "menuentry" {
                inmenu = 1;
                found = 0;
                id = "";
                for (i = 1; i <= NF; i++) {
                  if ($i == "--id") {
                    id = $(i + 1);
                    gsub(/'\''/, "", id);
                  }
                }
              }
              inmenu && ($1 == "linux" || $1 == "linuxefi") && index($0, k) { found = 1; }
              inmenu && found && id != "" { print id; exit }
              inmenu && $1 == "}" { inmenu = 0; found = 0; id = ""; }
            ' "$grub_cfg"
          )"

          if [ -z "$entry_id" ]; then
            echo "grub-boot-success: failed to resolve entry id" >&2
            exit 0
          fi

          ${pkgs.grub2}/bin/grub-editenv "$grub_env" set "last_successful=$entry_id"
          ${pkgs.grub2}/bin/grub-editenv "$grub_env" unset recordfail || \
            ${pkgs.grub2}/bin/grub-editenv "$grub_env" set recordfail=0
        '';
      };
    }
  ];
}
