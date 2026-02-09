{ lib, pkgs, config, ... }:
let
  cfg = config.bowenos.efiMirror;
  bootbById = config.bowenos.storage.bootbById;
  bootbDiskPath = config.bowenos.storage.bootbDiskPath;
  derivedDisk = if bootbById == "" then "/dev/disk/by-id/BOOTB_PLACEHOLDER" else (
    if lib.hasPrefix "/dev/" bootbById then bootbById else "/dev/disk/by-id/" + bootbById
  );

  mirrorDisk = if bootbDiskPath == "" then derivedDisk else bootbDiskPath;
in
{
  options.bowenos.efiMirror = {
    enable = lib.mkEnableOption "Mirror EFI boot files and (optionally) add a fallback EFI boot entry";
    mirrorMount = lib.mkOption { type = lib.types.str; default = "/boot-mirror"; };
    mirrorPart = lib.mkOption { type = lib.types.int; default = 1; };
    bootLabel = lib.mkOption { type = lib.types.str; default = "NixOS (mirror)"; };
    createBootEntry = lib.mkOption { type = lib.types.bool; default = true; };
    mountNoFail = lib.mkOption { type = lib.types.bool; default = true; };
    createSpecialisation = lib.mkOption { type = lib.types.bool; default = true; };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rsync pkgs.efibootmgr pkgs.util-linux ];

    fileSystems."${cfg.mirrorMount}".options =
      lib.optionals cfg.mountNoFail [ "nofail" "x-systemd.device-timeout=1s" ];

    system.activationScripts.efiMirror = ''
      set -euo pipefail
      if mountpoint -q "${cfg.mirrorMount}"; then
        echo "Syncing /boot -> ${cfg.mirrorMount} ..."
        ${pkgs.rsync}/bin/rsync -a --delete /boot/ ${cfg.mirrorMount}/
      else
        echo "EFI mirror mount ${cfg.mirrorMount} not mounted; skipping sync."
      fi
    '';

    systemd.services.efi-mirror-bootentry = lib.mkIf cfg.createBootEntry {
      description = "Ensure EFI boot entry exists for mirrored ESP";
      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Type = "oneshot"; };
      script = ''
        set -euo pipefail
        if [ ! -d /sys/firmware/efi/efivars ]; then
          echo "Not booted in UEFI mode; skipping efibootmgr."
          exit 0
        fi

        if ${pkgs.efibootmgr}/bin/efibootmgr | grep -Fq "${cfg.bootLabel}"; then
          echo "EFI entry '${cfg.bootLabel}' already exists."
          exit 0
        fi

        echo "Creating EFI boot entry '${cfg.bootLabel}' on ${mirrorDisk} part ${toString cfg.mirrorPart}..."
        ${pkgs.efibootmgr}/bin/efibootmgr           --create           --disk "${mirrorDisk}"           --part "${toString cfg.mirrorPart}"           --label "${cfg.bootLabel}"           --loader '\EFI\systemd\systemd-bootx64.efi'           || true
      '';
    };

    # Optional: create a specialisation that points systemd-boot at the mirror mount.
    specialisation.efi-mirror.configuration = lib.mkIf cfg.createSpecialisation {
      boot.loader.efi.efiSysMountPoint = cfg.mirrorMount;
      # Keep the mirror updated in this specialisation as well.
      system.activationScripts.efiMirror = ''
        set -euo pipefail
        if mountpoint -q "${cfg.mirrorMount}"; then
          echo "Syncing /boot -> ${cfg.mirrorMount} ..."
          ${pkgs.rsync}/bin/rsync -a --delete /boot/ ${cfg.mirrorMount}/
        else
          echo "EFI mirror mount ${cfg.mirrorMount} not mounted; skipping sync."
        fi
      '';
    };
  };
}
