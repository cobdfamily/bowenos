{ lib, options, ... }:
let
  hasBowenosToolsOption = lib.hasAttrByPath [ "services" "bowenos-tools" "enable" ] options;
in
{
  imports = [
    ./imports/bowenos-tools-import.nix
  ];

  config = lib.mkIf hasBowenosToolsOption {
    services.bowenos-tools = {
      enable = true;
    };
  };
}
