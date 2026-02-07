# BowenOS (ready to install)

BowenOS is a family of NixOS-based systems tuned for accessibility, reliability, and modern computing needs.

This repo provides two flake targets (roles):

- `compute`: Incus host (ZFS-backed) + LAN bridge profile
- `computeplusstorage`: everything in `compute` **plus** NFS server enabled + iSCSI targets from per-target files

## What you get
Both roles include:
- ZFS mirrored boot pool via **disko**
- Ephemeral root via **impermanence**
  - persists: `/var/log`, `/var/lib/incus`, `/opt/cprail`
- SSH locked down to **keys only**, **root login disabled**
- Admin user created at build time from env vars
- Incus init + ZFS-backed Incus storage pool
- Default NAT network (`incusbr0`) and a `bridge-to-lan` profile bridged to host `br0`
- Host bridge `br0` that enslaves `en*` NICs and uses DHCP on `br0`
- EFI mirror sync from `/boot` to `/boot-mirror` and a best-effort EFI boot entry creation

`computeplusstorage` additionally includes:
- NFS server enabled (you set `sharenfs` manually on ZFS datasets)
- iSCSI target application from `modules/iscsi/targets/*.nix` (you create zvols manually)

## Choosing a role (compute vs computeplusstorage)

### Install compute
```bash
TARGET=compute just disko
TARGET=compute just install
```

### Install computeplusstorage (default)
```bash
just disko
just install
```

You can also set `TARGET=compute` or `TARGET=computeplusstorage` in `.env`.

## Environment variables (implemented)

These are read during Nix evaluation using `builtins.getEnv`, so commands run with `--impure`
(the `just` recipes do this automatically). You can set them in `.env`, export them in your shell,
or pass them inline to `just`.

### Required
- `BOOTA_BYID` — boot disk A (by-id basename like `nvme-...` or full `/dev/...` path)
- `BOOTB_BYID` — boot disk B (by-id basename or full path)
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

### Optional
- `ROLE` — informational string written to `/etc/role`
- `TARGET` — choose the flake target role for `just` (`compute` or `computeplusstorage`)
- `BOOTB_DISK_PATH` — explicit disk path for efibootmgr (default derived from `BOOTB_BYID`)

## Install steps (from NixOS installer)

1) Clone the repo into `/mnt/etc/nixos`:
```bash
mkdir -p /mnt/etc
git clone https://github.com/cobdfamily/bowenos /mnt/etc/nixos
cd /mnt/etc/nixos/nixos
```

2) Create `.env`:
```bash
cp .env.example .env
nano .env
```

3) Partition + create mirrored rpool (WIPES boot disks):
```bash
just disko
```

It will prompt `y/N` before wiping. Use `FORCE=1 just disko` to skip prompting.

4) Install:
```bash
just install
reboot
```

## After boot
```bash
cd /etc/nixos/nixos
just switch
```

## NFS (computeplusstorage only)
NFS service is enabled. You set per-dataset exports manually, e.g.:
```bash
zfs set sharenfs="rw=@192.168.1.0/24,no_subtree_check,async" tank/nfs
```

## iSCSI (computeplusstorage only)
Targets live in `modules/iscsi/targets/*.nix`.
You create zvols manually (e.g. `tank/vmstore`) and reference them as `/dev/zvol/...`.

Check backing devices exist:
```bash
just iscsi-check
```

Apply changes:
```bash
just switch
```
