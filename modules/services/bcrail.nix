{ lib, pkgs, config, inputs, ... }:
let
  cfg = config.bowenos.bcrail;
  bcrail = inputs.bcrail;
in
{
  imports = [ bcrail.nixosModules.default ];

  options.bowenos.bcrail = {
    enable = lib.mkEnableOption "bcrail integration";

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bcrail";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/bcrail";
    };

    bridge = lib.mkOption {
      type = lib.types.str;
      default = "incusbr0";
    };

    pool = lib.mkOption {
      type = lib.types.str;
      default = "zfs-ssd";
    };

    remoteUser = lib.mkOption {
      type = lib.types.str;
      default = "vancouver";
    };

    stateDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    setupOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    bowenos.bcrail.enable = lib.mkDefault true;

    services.bcrail = lib.mkIf cfg.enable {
      enable = true;
      package = bcrail.packages.${pkgs.system}.bcrail;

      stateDir = cfg.stateDir;
      configDir = cfg.configDir;
      network.bridge = cfg.bridge;
      storage.pool = cfg.pool;
      remoteUser = cfg.remoteUser;
      stateDevice = cfg.stateDevice;
      setupOnBoot = cfg.setupOnBoot;

      ignitionFile = bcrail + "/etc/bcrail/ignition.json";
      locomotiveEnvFile = bcrail + "/etc/bcrail/locomotive.env";
    };
  };
}
