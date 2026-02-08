{ lib, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;
  getBool = name: def: (get name (if def then "true" else "false")) == "true";

  adminUser = get "ADMIN_USER" "admin";

  keyFromVar = builtins.getEnv "SSH_PUBKEY";
  keyFile = builtins.getEnv "SSH_PUBKEY_FILE";
  keyFromFile = if keyFile == "" then "" else builtins.readFile keyFile;
  sshKeyRaw = if keyFromVar != "" then keyFromVar else keyFromFile;
  sshKey = lib.strings.removeSuffix "\r" (lib.strings.removeSuffix "\n" sshKeyRaw);
in
{
  config = {
    bowenos.identity.hostName = lib.mkDefault (get "HOSTNAME" "server");
    bowenos.identity.hostId = lib.mkDefault (get "HOSTID" "");
    bowenos.identity.timeZone = lib.mkDefault (get "TIMEZONE" "America/Vancouver");
    bowenos.identity.locale = lib.mkDefault (get "LOCALE" "en_CA.UTF-8");
    bowenos.identity.target = lib.mkDefault (get "TARGET" "unknown");

    bowenos.users.adminUser = lib.mkDefault adminUser;
    bowenos.users.sshPubKey = lib.mkDefault sshKey;
    bowenos.users.allowNoKey = lib.mkDefault (getBool "ALLOW_NO_SSH_KEY" false);
    bowenos.users.sudoNeedsPassword = lib.mkDefault (getBool "SUDO_NEEDS_PASSWORD" false);
    bowenos.users.mutableUsers = lib.mkDefault (getBool "MUTABLE_USERS" false);

    bowenos.storage.isVm = lib.mkDefault (getBool "IS_VM" false);
  };
}
