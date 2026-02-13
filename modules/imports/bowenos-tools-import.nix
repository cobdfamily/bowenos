args@{ lib, ... }:
let
  hasInputs = args ? inputs;
  inputs = if hasInputs then args.inputs else { };
  hasBowenosToolsModule =
    hasInputs
    && (inputs ? bowenos-tools)
    && (inputs.bowenos-tools ? nixosModules)
    && (inputs.bowenos-tools.nixosModules ? default);
  hasBowenosToolsOverlay =
    hasInputs
    && (inputs ? bowenos-tools)
    && (inputs.bowenos-tools ? overlays)
    && (inputs.bowenos-tools.overlays ? default);
in
{
  imports = lib.optionals hasBowenosToolsModule [ inputs.bowenos-tools.nixosModules.default ];

  config = lib.mkIf hasBowenosToolsOverlay {
    nixpkgs.overlays = [ inputs.bowenos-tools.overlays.default ];
  };
}
