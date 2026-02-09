{
  target = "computeplusstorage";
  system = "x86_64-linux";

  # Disk IDs for disko
  bootaById = "nvme-EXAMPLE_DISK_A";
  bootbById = "nvme-EXAMPLE_DISK_B";

  module = { ... }: {
    bowenos.identity = {
      hostName = "spruce";
      hostId = "deadbeef";
      timeZone = "America/Vancouver";
      locale = "en_CA.UTF-8";
      target = "computeplusstorage";
    };

    bowenos.users = {
      adminUser = "leonard";
      sshPubKey = "ssh-ed25519 AAAA... your@key";
      allowNoKey = false;
      sudoNeedsPassword = false;
      mutableUsers = false;
      consolePassword = "";
    };

    bowenos.storage = {
      diskMode = "mirror";
      bootMode = "uefi";
      isVm = false;
      bootbDiskPath = "/dev/disk/by-id/EXAMPLE_DISK_B";
      bootaById = "nvme-EXAMPLE_DISK_A";
      bootbById = "nvme-EXAMPLE_DISK_B";
    };
  };
}
