{ lib, ... }:
{
  options.bowenos = {
    identity = {
      hostName = lib.mkOption { type = lib.types.str; default = "server"; };
      hostId = lib.mkOption { type = lib.types.str; default = ""; };
      timeZone = lib.mkOption { type = lib.types.str; default = "America/Vancouver"; };
      locale = lib.mkOption { type = lib.types.str; default = "en_CA.UTF-8"; };
      role = lib.mkOption { type = lib.types.str; default = "unknown"; };
    };

    users = {
      adminUser = lib.mkOption { type = lib.types.str; default = "admin"; };
      sshPubKey = lib.mkOption { type = lib.types.str; default = ""; };
      allowNoKey = lib.mkOption { type = lib.types.bool; default = false; };
      sudoNeedsPassword = lib.mkOption { type = lib.types.bool; default = false; };
      mutableUsers = lib.mkOption { type = lib.types.bool; default = false; };
    };

    storage = {
      diskMode = lib.mkOption { type = lib.types.enum [ "mirror" "single" ]; default = "mirror"; };
    };
  };
}
