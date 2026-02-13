args@{ lib, pkgs, options, ... }:
let
  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBcrailInput = hasInputs && (inputs ? bcrail) && (inputs.bcrail != null);
  hasServicesBcrail = options ? services && options.services ? bcrail;
  bcrail = if hasBcrailInput then inputs.bcrail else { };
in
{
  imports = lib.optionals hasBcrailInput [ bcrail.nixosModules.default ];

  config = lib.mkIf (hasBcrailInput && hasServicesBcrail) {
      services.bcrail.enable = lib.mkDefault true;
      services.bcrail.package = lib.mkDefault bcrail.packages.${pkgs.system}.bcrail;
      services.bcrail.stateDir = lib.mkDefault "/var/lib/bcrail";
      services.bcrail.configDir = lib.mkDefault "/etc/bcrail";
      services.bcrail.network.bridge = lib.mkDefault "incusbr0";
      services.bcrail.storage.pool = lib.mkDefault "zfs-ssd";
      services.bcrail.remoteUser = lib.mkDefault "vancouver";
      services.bcrail.stateDevice = lib.mkDefault null;
      services.bcrail.setupOnBoot = lib.mkDefault false;
  };
}
