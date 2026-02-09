{ lib, config, ... }:
let
  hostId = config.bowenos.identity.hostId;
  hostIdValid = builtins.match "^[0-9a-fA-F]{8}$" hostId != null;
in
{
  imports =
    []
    ++ (lib.optional (builtins.pathExists ../local.nix) ../local.nix);

  options.bowenos = {
    identity = {
      hostName = lib.mkOption { type = lib.types.str; default = "server"; };
      hostId = lib.mkOption { type = lib.types.str; default = ""; };
      timeZone = lib.mkOption { type = lib.types.str; default = "America/Vancouver"; };
      locale = lib.mkOption { type = lib.types.str; default = "en_CA.UTF-8"; };
      target = lib.mkOption { type = lib.types.str; default = "unknown"; };
    };

    users = {
      adminUser = lib.mkOption { type = lib.types.str; default = "admin"; };
      sshPubKey = lib.mkOption { type = lib.types.str; default = ""; };
      allowNoKey = lib.mkOption { type = lib.types.bool; default = false; };
      sudoNeedsPassword = lib.mkOption { type = lib.types.bool; default = false; };
      mutableUsers = lib.mkOption { type = lib.types.bool; default = false; };
      consolePassword = lib.mkOption { type = lib.types.str; default = ""; };
    };

    storage = {
      diskMode = lib.mkOption { type = lib.types.enum [ "mirror" "single" ]; default = "mirror"; };
      isVm = lib.mkOption { type = lib.types.bool; default = false; };
      bootaById = lib.mkOption { type = lib.types.str; default = ""; };
      bootbById = lib.mkOption { type = lib.types.str; default = ""; };
      bootMode = lib.mkOption { type = lib.types.enum [ "uefi" "bios" ]; default = "uefi"; };
      bootbDiskPath = lib.mkOption { type = lib.types.str; default = ""; };
    };
  };

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
