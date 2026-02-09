{
  # Required: which target to build (compute, computeplusstorage, storage)
  target = "computeplusstorage";

  # Optional: override system (default is x86_64-linux)
  system = "x86_64-linux";

  # Required: disk IDs for disko (used by install.sh disko)
  # Use /dev/disk/by-id basenames, not full paths.
  bootaById = "nvme-EXAMPLE_DISK_A";
  bootbById = "nvme-EXAMPLE_DISK_B";

  # Host module: set bowenos.* directly (no short-form mapping).
  module = { ... }: {
    bowenos.identity = {
      hostName = "spruce";
      hostId = "deadbeef"; # 8 hex chars
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
      diskMode = "mirror"; # mirror or single
      bootMode = "uefi";   # uefi or bios
      isVm = false;        # true uses /dev/disk/by-path in initrd

      # Optional: explicit /dev/... path for efibootmgr
      bootbDiskPath = "/dev/disk/by-id/EXAMPLE_DISK_B";

      # Required: disk IDs also set here for runtime
      bootaById = "nvme-EXAMPLE_DISK_A";
      bootbById = "nvme-EXAMPLE_DISK_B";
    };
  };
}
