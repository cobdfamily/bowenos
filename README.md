# BowenOS (ready to install)

BowenOS is a family of NixOS-based systems tuned for accessibility, reliability, and modern computing needs.

This repo provides four flake targets:

- `compute`: Incus host (ZFS-backed) + LAN bridge profile
- `computeplusstorage`: everything in `compute` **plus** NFS server enabled + iSCSI targets from per-target files
- `storage`: NFS + iSCSI server without Incus
- `spine`: VM profile with ext4 `/nix` + ext4 `/persist` (on `/dev/sdb`), ephemeral root, and Docker tooling

## What you get
All targets include:
- Ephemeral root via **impermanence**
  - persists (directories): `/etc/bowenos`, `/etc/bcrail`, `/var/lib/bcrail`, `/var/lib/incus`, `/var/lib/nixos`, `/var/log`
  - persists (files): `/etc/adjtime`, `/etc/machine-id`, `/etc/ssh/ssh_host_ecdsa_key`, `/etc/ssh/ssh_host_ecdsa_key.pub`, `/etc/ssh/ssh_host_ed25519_key`, `/etc/ssh/ssh_host_ed25519_key.pub`, `/etc/ssh/ssh_host_rsa_key`, `/etc/ssh/ssh_host_rsa_key.pub`, `/var/lib/dbus/machine-id`
- SSH locked down to **keys only**, **root login disabled**
- Admin user created at build time from env vars

`compute`/`computeplusstorage`/`storage` additionally include:
- ZFS mirrored boot pool via **Disko**
- GRUB with mirrored EFI partitions (`/boot` and `/bootB`)

`compute`/`computeplusstorage` additionally include:
- Incus init + ZFS-backed Incus storage pool
- Default NAT network (`incusbr0`) and a `bridge-to-lan` profile bridged to host `br0`
- Host bridge `br0` that enslaves `en*` NICs and uses DHCP on `br0`

`computeplusstorage`/`storage` additionally include:
- NFS server enabled (you set `sharenfs` manually on ZFS datasets)
- iSCSI target application from `modules/services/iscsi/targets/*.nix` (you create zvols manually)

`spine` additionally includes:
- ext4 `/nix` on remaining boot disk space and ext4 `/persist` on `/dev/sdb` (`diskMode = "single"`)
- Docker engine and docker-compose package

## Choosing a target

Set the target in host inventory (`target = "compute"`, `target = "computeplusstorage"`, `target = "storage"`, or `target = "spine"`), then run:

```bash
nix run github:cobdfamily/bowenos-tools -- partition
nix run github:cobdfamily/bowenos-tools -- install
```

## Host inventory (recommended)

`nix run github:cobdfamily/bowenos-tools -- setup` creates `/tmp/bowenos` from a fresh shallow clone of `bowenos-inventory-template` and writes host settings to `hosts/<hostname>/local.nix`.
For long-lived production inventory, keep the same host structure in your `bowenos-inventory` repository.
These are mapped into `bowenos.*` by the inventory flake.

Key fields:
- `target` — `compute`, `computeplusstorage`, `storage`, or `spine` (validated at partition time)
- `hostId` — 8 hex chars (required)
- `timeZone`, `locale`
- `adminUser`, `sshPubKey`, `allowNoKey`, `sudoNeedsPassword`, `mutableUsers`, `consolePassword`
- `diskMode` — `mirror` or `single`
- `bootMode` — `uefi` or `bios`
- `isVm` — `true` to use `/dev/disk/by-path` in initrd
- `bootaById`, `bootbById` — disk by-id basenames
- `bootbDiskPath` — explicit `/dev/...` path for efibootmgr (optional)

## Install steps (from NixOS installer)

For current command behavior, run:
```bash
nix run github:cobdfamily/bowenos-tools -- help
```

1) Create `/tmp/bowenos` inventory:
```bash
nix run github:cobdfamily/bowenos-tools -- setup
```
`setup` validates hostname characters, host ID format (`8` hex chars), and SSH key prefix (`ssh-...`).
For `diskMode = "mirror"`, setup and partitioning require at least two distinct disks.

2) Apply target disk layout with Disko (DESTRUCTIVE):
```bash
nix run github:cobdfamily/bowenos-tools -- partition
```

It will prompt `y/N` before wiping. Use `FORCE=1 nix run github:cobdfamily/bowenos-tools -- partition` to skip prompting.
Ensure `/mnt/persist` is mounted (inventory is copied to `/mnt/persist/etc/bowenos`) before running `install`.

3) Install NixOS for selected inventory host:
```bash
nix run github:cobdfamily/bowenos-tools -- install
reboot
```

## After boot
Switch system for current host:
```bash
cd /etc/bowenos
nix run github:cobdfamily/bowenos-tools -- update
```

## NFS (computeplusstorage/storage only)
NFS service is enabled. You set per-dataset exports manually, e.g.:
```bash
zfs set sharenfs="rw=@192.168.1.0/24,no_subtree_check,async" tank/nfs
```

## iSCSI (computeplusstorage/storage only)
Targets live in `modules/services/iscsi/targets/*.nix`.
You create zvols manually (e.g. `tank/vmstore`) and reference them as `/dev/zvol/...`.

Apply changes:
```bash
nix run github:cobdfamily/bowenos-tools -- update
```
