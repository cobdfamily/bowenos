{ lib, pkgs, config, ... }:
let
  cfg = config.bowenos.incusPreseed;
in {
  options.bowenos.incusPreseed = {
    enable = lib.mkEnableOption "Initialize Incus automatically";
    storagePoolName = lib.mkOption { type = lib.types.str; default = "zfs-ssd"; };
    zfsSource = lib.mkOption { type = lib.types.str; default = "rpool/incus"; };
    createDefaultNetwork = lib.mkOption { type = lib.types.bool; default = true; };
    createLanProfile = lib.mkOption { type = lib.types.bool; default = true; };
    lanBridgeParent = lib.mkOption { type = lib.types.str; default = "br0"; };
    defaultProfile = lib.mkOption { type = lib.types.str; default = "default"; };
    lanProfileName = lib.mkOption { type = lib.types.str; default = "bridge-to-lan"; };
  };

  config = lib.mkIf cfg.enable {
      # Incus requires nftables on NixOS.
      networking.nftables.enable = true;

      virtualisation.incus.enable = true;
      environment.systemPackages = [ pkgs.incus pkgs.jq pkgs.zfs ];
      networking.firewall.allowedTCPPorts = [ 8443 ];

      systemd.services.incus-preseed = {
        description = "Init Incus + storage pool + profiles";
        after = [ "network-online.target" "zfs-mount.service" "incus.service" ];
        requires = [ "incus.service" ];
        wants = [ "network-online.target" "incus.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
        script = ''
          set -euo pipefail
          if ${pkgs.incus}/bin/incus info >/dev/null 2>&1; then echo "Incus already initialized."; else ${pkgs.incus}/bin/incus admin init --minimal; fi

          if ! ${pkgs.zfs}/bin/zfs list -H -o name "${cfg.zfsSource}" >/dev/null 2>&1; then
            ${pkgs.zfs}/bin/zfs create -p "${cfg.zfsSource}"
          fi

          if ! ${pkgs.incus}/bin/incus storage list --format json | ${pkgs.jq}/bin/jq -e '.[] | select(.name=="${cfg.storagePoolName}")' >/dev/null; then
            ${pkgs.incus}/bin/incus storage create "${cfg.storagePoolName}" zfs source="${cfg.zfsSource}"
          fi

          if ! ${pkgs.incus}/bin/incus profile show "${cfg.defaultProfile}" | ${pkgs.gnugrep}/bin/grep -q '^  root:'; then
            ${pkgs.incus}/bin/incus profile device add "${cfg.defaultProfile}" root disk path=/ pool="${cfg.storagePoolName}"
          fi

          if ${lib.boolToString cfg.createDefaultNetwork}; then
            if ! ${pkgs.incus}/bin/incus network list --format json | ${pkgs.jq}/bin/jq -e '.[] | select(.name=="incusbr0")' >/dev/null; then
              ${pkgs.incus}/bin/incus network create incusbr0 ipv4.address=auto ipv4.nat=true ipv6.address=none
            fi
            if ! ${pkgs.incus}/bin/incus profile show "${cfg.defaultProfile}" | ${pkgs.gnugrep}/bin/grep -q '^  eth0:'; then
              ${pkgs.incus}/bin/incus profile device add "${cfg.defaultProfile}" eth0 nic nictype=bridged parent=incusbr0
            fi
          fi

          if ${lib.boolToString cfg.createLanProfile}; then
            if ! ${pkgs.incus}/bin/incus profile list --format json | ${pkgs.jq}/bin/jq -e '.[] | select(.name=="${cfg.lanProfileName}")' >/dev/null; then
              ${pkgs.incus}/bin/incus profile create "${cfg.lanProfileName}"
            fi
            if ! ${pkgs.incus}/bin/incus profile show "${cfg.lanProfileName}" | ${pkgs.gnugrep}/bin/grep -q '^  root:'; then
              ${pkgs.incus}/bin/incus profile device add "${cfg.lanProfileName}" root disk path=/ pool="${cfg.storagePoolName}"
            fi
            if ! ${pkgs.incus}/bin/incus profile show "${cfg.lanProfileName}" | ${pkgs.gnugrep}/bin/grep -q '^  eth0:'; then
              ${pkgs.incus}/bin/incus profile device add "${cfg.lanProfileName}" eth0 nic nictype=bridged parent="${cfg.lanBridgeParent}"
            fi
          fi
        '';
      };
  };
}
