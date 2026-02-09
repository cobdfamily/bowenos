{
  target = "computeplusstorage";
  module = { ... }: {
    bowenos.identity.hostId = "deadbeef";
    bowenos.identity.timeZone = "America/Vancouver";
    bowenos.identity.locale = "en_CA.UTF-8";

    bowenos.users.adminUser = "leonard";
    bowenos.users.sshPubKey = "ssh-ed25519 AAAA... your@key";
    bowenos.users.allowNoKey = false;
    bowenos.users.sudoNeedsPassword = false;
    bowenos.users.mutableUsers = false;
    bowenos.users.consolePassword = "";

    # Optional: override defaults
    # bowenos.storage.diskMode = "mirror";
    # bowenos.storage.isVm = false;
  };
}
