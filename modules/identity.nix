{ lib, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;
in {
  networking.hostName = get "HOSTNAME" "server";
  networking.hostId   = get "HOSTID" "deadbeef";

  time.timeZone = get "TIMEZONE" "America/Vancouver";
  i18n.defaultLocale = get "LOCALE" "en_CA.UTF-8";

  environment.etc."role".text = get "ROLE" "unknown";
}
