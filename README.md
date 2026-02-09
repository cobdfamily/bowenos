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
  - persists (directories): `/etc/ssh`, `/opt/cprail`, `/var/lib/incus`, `/var/lib/nixos`, `/var/lib/systemd/coredump`, `/var/log`
  - persists (files): `/etc/adjtime`, `/etc/machine-id`, `/var/lib/dbus/machine-id`
- SSH locked down to **keys only**, **root login disabled**
- Admin user created at build time from env vars
- EFI mirror sync from `/boot` to `/boot-mirror` and a best-effort EFI boot entry creation

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
TARGET=compute ./install/install.sh disko
TARGET=compute ./install/install.sh install
```

### Install computeplusstorage (default)
```bash
./install/install.sh disko
./install/install.sh install
```

### Install storage
```bash
TARGET=storage ./install/install.sh disko
TARGET=storage ./install/install.sh install
```

You can also set `TARGET=compute`, `TARGET=computeplusstorage`, or `TARGET=storage` in `.env`.

## Environment variables (implemented)

These are read during Nix evaluation using `builtins.getEnv`, so commands run with `--impure`.
You can set them in `.env` (in repo root) or export them in your shell.

### Required
- `BOOTA_BYID` — boot disk A (by-id basename like `nvme-...` or full `/dev/...` path)
- `BOOTB_BYID` — boot disk B (by-id basename or full path). Required when `DISK_MODE=mirror`.
- `HOSTID` — 8 hex characters (required by ZFS; example `deadbeef`)

### Strongly recommended
- `HOSTNAME` — hostname for the machine (letters/digits/hyphens)
- `ADMIN_USER` — admin username to create
- `SSH_PUBKEY` or `SSH_PUBKEY_FILE` — your public SSH key

### Locale / time
- `TIMEZONE` — e.g. `America/Vancouver`
- `LOCALE` — e.g. `en_CA.UTF-8`

### Safeguards / policy
- `SUDO_NEEDS_PASSWORD` — `true` or `false`
- `ALLOW_NO_SSH_KEY` — `true` to allow console-only bootstrap without a key
- `MUTABLE_USERS` — `true` to allow manual user/group changes outside Nix; default is immutable users for reproducibility

### Optional
- `TARGET` — choose the flake target (`compute`, `computeplusstorage`, or `storage`); written to `/etc/bowenos-target`
- `BOOT_MODE` — `uefi` (default) or `bios` (uses GRUB when `bios`)
- `IS_VM` — `true` to use `/dev/disk/by-path` in initrd (useful when by-id links are unreliable in VMs)
- `BOOTB_DISK_PATH` — explicit disk path for efibootmgr (default derived from `BOOTB_BYID`)

## Install steps (from NixOS installer)

1) Clone the repo somewhere safe (not under `/mnt`, because `disko` will wipe `/mnt`):
```bash
git clone https://github.com/cobdfamily/bowenos /root/bowenos
cd /root/bowenos
```

2) Partition + create mirrored rpool (WIPES boot disks):
```bash
./install/install.sh disko
```

It will prompt `y/N` before wiping. Use `FORCE=1 ./install/install.sh disko` to skip prompting.

3) Clone the repo into `/mnt/etc/nixos`:
```bash
mkdir -p /mnt/etc
git clone https://github.com/cobdfamily/bowenos /mnt/etc/nixos
cd /mnt/etc/nixos
```

4) Create `.env`:
```bash
cp .env.example .env
nano .env
```

5) Install:
```bash
./install/install.sh install
reboot
```

## After boot
```bash
cd /etc/nixos
./install/install.sh switch
```

## EFI mirror specialisation
If the primary EFI partition is unavailable, you can boot the specialisation that
uses the mirror mount point. In the systemd-boot menu, choose the entry labeled
`NixOS - efi-mirror`.

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
./install/install.sh iscsi-check
```

Apply changes:
```bash
./install/install.sh switch
```
