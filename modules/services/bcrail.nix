args@{ lib, pkgs, config, ... }:
let
  cfg = config.bowenos.bcrail;
  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else null;
  hasBcrailInput = hasInputs && (inputs ? bcrail);
  bcrail = if hasBcrailInput then inputs.bcrail else null;
in {
  imports = lib.optional hasBcrailInput bcrail.nixosModules.default;

  options.bowenos.bcrail = {
    enable = lib.mkEnableOption "bcrail service";
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

        stateDir = "/var/lib/bcrail";
        configDir = "/etc/bcrail";

        network.bridge = cfg.bridge;
        storage.pool = cfg.pool;
        remoteUser = cfg.remoteUser;
        stateDevice = cfg.stateDevice;

        ignitionFile = bcrail + "/etc/bcrail/ignition.json";
        locomotiveEnvFile = bcrail + "/etc/bcrail/locomotive.env";

        inherit (cfg) setupOnBoot;
      };
    } else {})
  ];
}
