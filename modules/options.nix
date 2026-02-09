{ lib, ... }:
{
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
}
