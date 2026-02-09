# Hosts Inventory

Each host lives in its own directory:

```
hosts/<hostname>/
  local.nix
  hardware-configuration.nix
```

`local.nix` must export:

```nix
{
  target = "computeplusstorage"; # or compute/storage
  system = "x86_64-linux";       # optional

  # Short-form keys (expanded to bowenos.*)
  hostName = "spruce";           # optional (defaults to dir name)
  hostId = "deadbeef";
  timeZone = "America/Vancouver";
  locale = "en_CA.UTF-8";

  adminUser = "leonard";
  sshPubKey = "ssh-ed25519 AAAA... your@key";
  allowNoKey = false;
  sudoNeedsPassword = false;
  mutableUsers = false;
  consolePassword = "";

  diskMode = "mirror";
  bootMode = "uefi";
  isVm = false;
  bootbDiskPath = "/dev/disk/by-id/EXAMPLE_DISK_B";

  # Disk IDs for disko (used by install.sh disko)
  bootaById = "nvme-EXAMPLE_DISK_A";
  bootbById = "nvme-EXAMPLE_DISK_B";

  # Optional: full module for advanced overrides
  module = { ... }: { };
}
```

`local.nix` is the host-specific config (tracked), and
`hardware-configuration.nix` is the standard output of `nixos-generate-config`.
