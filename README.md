# BowenOS (ready to install)

BowenOS is a family of NixOS-based systems tuned for accessibility, reliability, and modern computing needs.

This repo provides three flake targets:

- `compute`: Incus host (ZFS-backed) + LAN bridge profile
- `computeplusstorage`: everything in `compute` **plus** NFS server enabled + iSCSI targets from per-target files
- `storage`: NFS + iSCSI server without Incus

## What you get
All targets include:
- ZFS mirrored boot pool via **disko**
- Ephemeral root via **impermanence**
  - persists (directories): `/etc/bowenos`, `/opt/cprail`, `/var/lib/incus`, `/var/lib/nixos`, `/var/lib/systemd/coredump`, `/var/log`
  - persists (files): `/etc/adjtime`, `/etc/hostid`, `/etc/machine-id`, `/etc/ssh/ssh_host_ecdsa_key`, `/etc/ssh/ssh_host_ecdsa_key.pub`, `/etc/ssh/ssh_host_ed25519_key`, `/etc/ssh/ssh_host_ed25519_key.pub`, `/etc/ssh/ssh_host_rsa_key`, `/etc/ssh/ssh_host_rsa_key.pub`, `/var/lib/dbus/machine-id`
- SSH locked down to **keys only**, **root login disabled**
- Admin user created at build time from env vars
- GRUB with mirrored EFI partitions (`/boot` and `/boot-fallback`)

`compute`/`computeplusstorage` additionally include:
- Incus init + ZFS-backed Incus storage pool
- Default NAT network (`incusbr0`) and a `bridge-to-lan` profile bridged to host `br0`
- Host bridge `br0` that enslaves `en*` NICs and uses DHCP on `br0`

`computeplusstorage`/`storage` additionally include:
- NFS server enabled (you set `sharenfs` manually on ZFS datasets)
- iSCSI target application from `modules/services/iscsi/targets/*.nix` (you create zvols manually)

## Choosing a target

### Install compute
```bash
nix run github:cobdfamily/bowenos-tools -- partition
nix run github:cobdfamily/bowenos-tools -- install
```

### Install computeplusstorage (default)
```bash
nix run github:cobdfamily/bowenos-tools -- partition
nix run github:cobdfamily/bowenos-tools -- install
```

### Install storage
```bash
nix run github:cobdfamily/bowenos-tools -- partition
nix run github:cobdfamily/bowenos-tools -- install
```

Set the target in host inventory (`target = "compute"`, `target = "computeplusstorage"`, or `target = "storage"`), then run `partition` and `install`.

## Host inventory (recommended)

`nix run github:cobdfamily/bowenos-tools -- setup` creates `/tmp/bowenos` from `bowenos-inventory-template` and writes host settings to `hosts/<hostname>/local.nix`.
For long-lived production inventory, keep the same host structure in your `bowenos-inventory` repository.
These are mapped into `bowenos.*` by the inventory flake.

Key fields:
- `target` — `compute`, `computeplusstorage`, or `storage`
- `hostId` — 8 hex chars (required by ZFS)
- `timeZone`, `locale`
- `adminUser`, `sshPubKey`, `allowNoKey`, `sudoNeedsPassword`, `mutableUsers`, `consolePassword`
- `diskMode` — `mirror` or `single`
- `bootMode` — `uefi` or `bios`
- `isVm` — `true` to use `/dev/disk/by-path` in initrd
- `bootaById`, `bootbById` — disk by-id basenames
- `bootbDiskPath` — explicit `/dev/...` path for efibootmgr (optional)

## Install steps (from NixOS installer)

1) Clone the repo somewhere safe (not under `/mnt`, because partitioning will wipe `/mnt`):
```bash
git clone https://github.com/cobdfamily/bowenos /root/bowenos
cd /root/bowenos
```

2) Create inventory in `/tmp/bowenos`:
```bash
nix run github:cobdfamily/bowenos-tools -- setup
```

3) Partition + create mirrored rpool (WIPES boot disks):
```bash
nix run github:cobdfamily/bowenos-tools -- partition
```

It will prompt `y/N` before wiping. Use `FORCE=1 nix run github:cobdfamily/bowenos-tools -- partition` to skip prompting.

4) Install:
```bash
nix run github:cobdfamily/bowenos-tools -- install
reboot
```

## After boot
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
