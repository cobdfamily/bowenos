{ lib, config, ... }:
let
  hostId = config.bowenos.identity.hostId;
  hostIdValid = builtins.match "^[0-9a-fA-F]{8}$" hostId != null;
in
{
  imports =
    [
      ./options.nix
      ./env.nix
    ]
    ++ (lib.optional (builtins.pathExists ../local.nix) ../local.nix);

  assertions = [
    { assertion = hostId != ""; message = "HOSTID is required (8 hex chars)."; }
    { assertion = hostIdValid; message = "HOSTID must be exactly 8 hex characters (0-9, a-f)."; }
  ];

  networking.hostName = config.bowenos.identity.hostName;
  networking.hostId = hostId;

  time.timeZone = config.bowenos.identity.timeZone;
  i18n.defaultLocale = config.bowenos.identity.locale;

  environment.etc."target".text = config.bowenos.identity.target;
}
