args@{ lib, pkgs, config, ... }:
let
  cfg = config.bowenos.bcrail;

  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBcrailInput = hasInputs && (inputs ? bcrail);
  bcrailInput = if hasBcrailInput then inputs.bcrail else null;
in
{
  imports = lib.optionals hasBcrailInput [ bcrailInput.nixosModules.default ];

  options.bowenos.bcrail = {
    enable = lib.mkEnableOption "bcrail integration";

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bcrail";
      description = "State directory used by bcrail contexts.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/bcrail";
      description = "Configuration directory used by bcrail.";
    };

    bridge = lib.mkOption {
      type = lib.types.str;
      default = "incusbr0";
      description = "Incus bridge name used by bcrail.";
    };

    pool = lib.mkOption {
      type = lib.types.str;
      default = "zfs-ssd";
      description = "Incus storage pool name used by bcrail.";
    };

    remoteUser = lib.mkOption {
      type = lib.types.str;
      default = "vancouver";
      description = "SSH user used by bcrail helpers for remote VM operations.";
    };

    stateDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional block device path inside guest for bcrail state disk.";
    };

    setupOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to run bcrail setup during boot.";
    };
  };

  config = lib.mkMerge [
    {
      bowenos.bcrail.enable = lib.mkDefault hasBcrailInput;
    }
    {
      assertions = [
        {
          assertion = (!cfg.enable) || hasBcrailInput;
          message = "bowenos.bcrail.enable requires flake input 'bcrail' and passing 'inputs' in specialArgs.";
        }
      ];
    }
    (if cfg.enable && hasBcrailInput then {
      services.bcrail = {
        enable = true;
        package = bcrailInput.packages.${pkgs.system}.bcrail;

        stateDir = cfg.stateDir;
        configDir = cfg.configDir;
        network.bridge = cfg.bridge;
        storage.pool = cfg.pool;
        remoteUser = cfg.remoteUser;
        stateDevice = cfg.stateDevice;
        setupOnBoot = cfg.setupOnBoot;

        ignitionFile = bcrailInput + "/etc/bcrail/ignition.json";
        locomotiveEnvFile = bcrailInput + "/etc/bcrail/locomotive.env";
      };
    } else { })
  ];
}
