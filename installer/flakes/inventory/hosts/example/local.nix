{
  target = "computeplusstorage";
  hostId = "deadbeef";
  timeZone = "America/Vancouver";
  locale = "en_CA.UTF-8";

  adminUser = "leonard";
  sshPubKey = "ssh-ed25519 AAAA... your@key";
  allowNoKey = false;
  sudoNeedsPassword = false;
  mutableUsers = false;
  consolePassword = "";

  # Optional: override defaults
  # diskMode = "mirror";
  # bootMode = "uefi";
  # isVm = false;
  # bootbDiskPath = "/dev/disk/by-id/EXAMPLE_DISK_B";

  # Disk IDs for disko
  bootaById = "nvme-EXAMPLE_DISK_A";
  bootbById = "nvme-EXAMPLE_DISK_B";
}
