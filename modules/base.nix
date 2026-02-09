{ lib, config, ... }:
let
  hostId = config.bowenos.identity.hostId;
  hostIdValid = builtins.match "^[0-9a-fA-F]{8}$" hostId != null;
  hwFromEnv = builtins.getEnv "BOWENOS_HARDWARE_CONFIG";
  hwPath =
    if hwFromEnv != "" && builtins.pathExists hwFromEnv then
      hwFromEnv
    else if builtins.pathExists /etc/nixos/hardware-configuration.nix then
      /etc/nixos/hardware-configuration.nix
    else if builtins.pathExists ../hardware-configuration.nix then
      ../hardware-configuration.nix
    else
      null;
in
{
  imports =
    [
      (if hwPath != null
       then hwPath
       else throw "hardware-configuration.nix is required (run ./install/install.sh hardware-scan)")
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

  environment.etc."bowenos-target".text = config.bowenos.identity.target;
}
