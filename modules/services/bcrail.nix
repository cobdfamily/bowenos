args@{ lib, pkgs, ... }:
let
  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBcrailInput = hasInputs && (inputs ? bcrail);
  bcrail = if hasBcrailInput then inputs.bcrail else null;
in
{
  imports = lib.optionals hasBcrailInput [ bcrail.nixosModules.default ];

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = hasBcrailInput;
          message = "modules/services/bcrail.nix requires flake input 'bcrail' passed through specialArgs.inputs.";
        }
      ];
    }
    (lib.mkIf hasBcrailInput {
      services.bcrail.enable = lib.mkDefault true;
      services.bcrail.package = lib.mkDefault bcrail.packages.${pkgs.system}.bcrail;
      services.bcrail.stateDir = lib.mkDefault "/var/lib/bcrail";
      services.bcrail.configDir = lib.mkDefault "/etc/bcrail";
      services.bcrail.network.bridge = lib.mkDefault "incusbr0";
      services.bcrail.storage.pool = lib.mkDefault "zfs-ssd";
      services.bcrail.remoteUser = lib.mkDefault "vancouver";
      services.bcrail.stateDevice = lib.mkDefault null;
      services.bcrail.setupOnBoot = lib.mkDefault false;
      services.bcrail.ignitionFile = lib.mkDefault (bcrail + "/etc/bcrail/ignition.json");
      services.bcrail.locomotiveEnvFile = lib.mkDefault (bcrail + "/etc/bcrail/locomotive.env");
    })
  ];
}
