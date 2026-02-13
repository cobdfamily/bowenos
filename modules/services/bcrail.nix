args@{ lib, pkgs, config, ... }:
let
  cfg = config.bowenos.bcrail;

  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBcrailInput = hasInputs && (inputs ? bcrail);
  bcrail = if hasBcrailInput then inputs.bcrail else null;
in
{
  imports = lib.optionals hasBcrailInput [ bcrail.nixosModules.default ];

  options.bowenos.bcrail = {
    enable = lib.mkEnableOption "bcrail integration";

    stateDir = lib.mkOption { type = lib.types.str; default = "/var/lib/bcrail"; };
    configDir = lib.mkOption { type = lib.types.str; default = "/etc/bcrail"; };
    bridge = lib.mkOption { type = lib.types.str; default = "incusbr0"; };
    pool = lib.mkOption { type = lib.types.str; default = "zfs-ssd"; };
    remoteUser = lib.mkOption { type = lib.types.str; default = "vancouver"; };
    stateDevice = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
    setupOnBoot = lib.mkOption { type = lib.types.bool; default = false; };
  };

  config = lib.mkMerge [
    { bowenos.bcrail.enable = lib.mkDefault hasBcrailInput; }
    {
      assertions = [
        {
          assertion = (!cfg.enable) || hasBcrailInput;
          message = "bowenos.bcrail.enable requires flake input 'bcrail' and passing 'inputs' in specialArgs.";
        }
      ];
    }
    (if (cfg.enable && hasBcrailInput) then {
      services.bcrail = {
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
    } else { })
  ];
}
