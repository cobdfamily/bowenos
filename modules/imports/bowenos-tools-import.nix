args@{ lib, ... }:
let
  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBcrailModule =
    hasInputs
    && (inputs ? bowenos-tools)
    && (inputs.bowenos-tools ? nixosModules)
    && (inputs.bowenos-tools.nixosModules ? default);
  hasBcrailOverlay =
    hasInputs
    && (inputs ? bowenos-tools)
    && (inputs.bowenos-tools ? overlays)
    && (inputs.bowenos-tools.overlays ? default);
in
{
  imports = lib.optionals hasBcrailModule [ inputs.bowenos-tools.nixosModules.default ];

  config = lib.mkIf hasBcrailOverlay {
    nixpkgs.overlays = [ inputs.bowenos-tools.overlays.default ];
  };
}
