# Testing NixOS (GRUB + Mirrored EFI + ZFS Root)

This folder contains a standalone, minimal NixOS system modeled after:
https://lowtek.ca/roo/2025/nixos-with-mirrored-zfs-boot-volume/

It uses:
- GRUB on UEFI with mirrored EFI partitions
- ZFS root with legacy mountpoint
- No Incus, NFS, or iSCSI

Build / switch (after replacing UUIDs and SSH key):
```bash
sudo nixos-rebuild switch --flake .#testing
```

## Install (with disko)
From the repo root:
```bash
export BOOTA_BYID=nvme-EXAMPLE_DISK_A
export BOOTB_BYID=nvme-EXAMPLE_DISK_B
nix run github:nix-community/disko -- --mode disko ./testing/disks.nix
sudo nixos-install --flake ./testing#testing
```
