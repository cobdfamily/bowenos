{ lib, ... }:
{
  # replace the root mount with tmpfs
  # wipes everything if you don't have proper persists, be warned
  fileSystems."/" = lib.mkForce {
    device = "tmpfs";
    fsType = "tmpfs";
    neededForBoot = true;
    options = [
      "defaults"
      # whatever size feels comfortable, smaller is better
      "size=1G"
      "mode=755"
    ];
  };
}
