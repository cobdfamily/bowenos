args@{ lib, ... }:
let
  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBcrailModule =
    hasInputs
    && (inputs ? bcrail)
    && (inputs.bcrail ? nixosModules)
    && (inputs.bcrail.nixosModules ? default);
  hasBcrailOverlay =
    hasInputs
    && (inputs ? bcrail)
    && (inputs.bcrail ? overlays)
    && (inputs.bcrail.overlays ? default);
in
{
  imports = lib.optionals hasBcrailModule [ inputs.bcrail.nixosModules.default ];

  config = lib.mkIf hasBcrailOverlay {
    nixpkgs.overlays = [ inputs.bcrail.overlays.default ];
  };
}
