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
TARGET=compute ./installer/bowenos disko
TARGET=compute ./installer/bowenos install
```

### Install computeplusstorage (default)
```bash
./installer/bowenos disko
./installer/bowenos install
```

### Install storage
```bash
TARGET=storage ./installer/bowenos disko
TARGET=storage ./installer/bowenos install
```

You can set the target via host inventory or by exporting `TARGET` for ad‑hoc runs.

## Host inventory (recommended)

All host-specific settings live in `flakes/inventory/hosts/<hostname>/local.nix`.
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

1) Clone the repo somewhere safe (not under `/mnt`, because `disko` will wipe `/mnt`):
```bash
git clone https://github.com/cobdfamily/bowenos /root/bowenos
cd /root/bowenos
```

2) Partition + create mirrored rpool (WIPES boot disks):
```bash
./installer/bowenos disko
```

It will prompt `y/N` before wiping. Use `FORCE=1 ./installer/bowenos disko` to skip prompting.

3) Clone the repo into `/mnt/etc/nixos`:
```bash
mkdir -p /mnt/etc
git clone https://github.com/cobdfamily/bowenos /mnt/etc/nixos
cd /mnt/etc/nixos
```

4) Install:
```bash
./installer/bowenos install
reboot
```

## After boot
```bash
cd /etc/nixos
./installer/bowenos switch
```

## NFS (computeplusstorage/storage only)
NFS service is enabled. You set per-dataset exports manually, e.g.:
```bash
zfs set sharenfs="rw=@192.168.1.0/24,no_subtree_check,async" tank/nfs
```

## iSCSI (computeplusstorage/storage only)
Targets live in `modules/services/iscsi/targets/*.nix`.
You create zvols manually (e.g. `tank/vmstore`) and reference them as `/dev/zvol/...`.

Check backing devices exist:
```bash
./installer/bowenos iscsi-check
```

Apply changes:
```bash
./installer/bowenos switch
```
