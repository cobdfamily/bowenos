args@{ lib, ... }:
let
  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBcrailModule =
    hasInputs
    && (inputs ? bcrail)
    && (inputs.bcrail ? nixosModules)
    && (inputs.bcrail.nixosModules ? default);
in
{
  imports = lib.optionals hasBcrailModule [ inputs.bcrail.nixosModules.default ];
}
