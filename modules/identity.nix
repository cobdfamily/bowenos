{ lib, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;
  hostId = get "HOSTID" "";
  hostIdValid = builtins.match "^[0-9a-fA-F]{8}$" hostId != null;
in {
  assertions = [
    { assertion = hostId != ""; message = "HOSTID is required (8 hex chars)."; }
    { assertion = hostIdValid; message = "HOSTID must be exactly 8 hex characters (0-9, a-f)."; }
  ];

  networking.hostName = get "HOSTNAME" "server";
  networking.hostId   = hostId;

  time.timeZone = get "TIMEZONE" "America/Vancouver";
  i18n.defaultLocale = get "LOCALE" "en_CA.UTF-8";

  environment.etc."role".text = get "ROLE" "unknown";
}
