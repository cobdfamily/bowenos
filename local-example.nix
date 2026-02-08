{
  bowenos.identity.hostName = "bowenos";
  bowenos.identity.hostId = "deadbeef";
  bowenos.identity.timeZone = "America/Vancouver";
  bowenos.identity.locale = "en_CA.UTF-8";
  bowenos.identity.target = "computeplusstorage";

  bowenos.users.adminUser = "leonard";
  bowenos.users.sshPubKey = "ssh-ed25519 AAAA... your@key";
  bowenos.users.allowNoKey = false;
  bowenos.users.sudoNeedsPassword = false;
  bowenos.users.mutableUsers = false;

  # Optional: override defaults
  # bowenos.storage.diskMode = "mirror";
  # bowenos.storage.isVm = false;
}
