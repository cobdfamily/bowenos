{ lib, pkgs, config, ... }:
let
  cfg = config.bowenos.iscsi;
  targetsDir = ./targets;

  targetFiles = lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n) (builtins.readDir targetsDir);
  targets = map (name: import (targetsDir + "/${name}")) (builtins.attrNames targetFiles);

  mkTargetcli = t: ''
    targetcli /iscsi create ${t.iqn} || true
    ${lib.concatStringsSep "\n" (map (lun: ''
      targetcli /backstores/block create ${lun.name} ${lun.backing} || true
      targetcli /iscsi/${t.iqn}/tpg1/luns create /backstores/block/${lun.name} || true
    '') t.luns)}
    ${lib.concatStringsSep "\n" (map (a: ''
      targetcli /iscsi/${t.iqn}/tpg1/acls create ${a.initiator} || true
    '') (t.acls or []))}
  '';
in
{
  options.bowenos.iscsi = {
    enable = lib.mkEnableOption "iSCSI targets via per-target files";
  };

  config = lib.mkIf cfg.enable {
    services.target.enable = true;
    environment.systemPackages = [ pkgs.targetcli pkgs.jq ];
    networking.firewall.allowedTCPPorts = [ 3260 ];

    systemd.services.iscsi-targets-apply = {
      description = "Apply iSCSI targets from modules/iscsi/targets/*.nix";
      after = [ "network-online.target" "local-fs.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        set -euo pipefail
        ${lib.concatStringsSep "\n\n" (map mkTargetcli targets)}
        targetcli saveconfig
      '';
    };
  };
}
