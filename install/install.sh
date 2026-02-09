#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env"
HARDWARE_FILE="${ROOT}/hardware-configuration.nix"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +a
fi

TARGET="${TARGET:-computeplusstorage}"
CMD="${1:-}"

usage() {
  cat <<'USAGE'
Usage: install.sh <command>

Commands:
  show-env     Print key environment values
  iso          Build the bootstrap ISO
  disko        Partition + create mirrored rpool (destructive)
  install      Run nixos-install for TARGET
  switch       Run nixos-rebuild switch for TARGET
  rebuild      Run nixos-rebuild switch for TARGET (no sudo)
  iscsi-check  Validate iSCSI backing devices exist
  hardware-scan  Generate hardware-configuration.nix into repo
  repair        Rebuild installed system mounted at /mnt (via nixos-enter)
USAGE
}

validate_hardware() {
  if [[ ! -f "${HARDWARE_FILE}" ]]; then
    echo "Missing ${HARDWARE_FILE}. Run ./install/install.sh hardware-scan" >&2
    exit 2
  fi

  if command -v nix-instantiate >/dev/null 2>&1; then
    nix-instantiate --parse "${HARDWARE_FILE}" >/dev/null
  fi

  if ! grep -q "boot.initrd.availableKernelModules" "${HARDWARE_FILE}"; then
    echo "hardware-configuration.nix is missing boot.initrd.availableKernelModules" >&2
    exit 2
  fi
}

case "${CMD}" in
  show-env)
    echo "TARGET=${TARGET}"
    echo "TARGET(from env)=${TARGET}"
    echo "HOSTNAME=${HOSTNAME:-}"
    echo "HOSTID=${HOSTID:-}"
    echo "TIMEZONE=${TIMEZONE:-}"
    echo "LOCALE=${LOCALE:-}"
    echo "BOOTA_BYID=${BOOTA_BYID:-}"
    echo "BOOTB_BYID=${BOOTB_BYID:-}"
    echo "BOOT_MODE=${BOOT_MODE:-}"
    echo "ADMIN_USER=${ADMIN_USER:-}"
    echo "SSH_PUBKEY set? $([[ -n ${SSH_PUBKEY:-} ]] && echo yes || echo no)"
    echo "SSH_PUBKEY_FILE=${SSH_PUBKEY_FILE:-}"
    echo "SUDO_NEEDS_PASSWORD=${SUDO_NEEDS_PASSWORD:-}"
    echo "ALLOW_NO_SSH_KEY=${ALLOW_NO_SSH_KEY:-}"
    echo "MUTABLE_USERS=${MUTABLE_USERS:-}"
    ;;
  iso)
    nix build "${ROOT}#iso"
    ;;
  disko)
    if [[ -z "${BOOTA_BYID:-}" || -z "${BOOTB_BYID:-}" ]]; then
      echo "Set BOOTA_BYID and BOOTB_BYID in .env or env." >&2
      exit 2
    fi
    if [[ "${FORCE:-0}" != "1" ]]; then
      echo "⚠️  About to WIPE and repartition:"
      echo "    BOOTA_BYID=${BOOTA_BYID}"
      echo "    BOOTB_BYID=${BOOTB_BYID}"
      read -r -p "Continue? (y/N) " ans
      case "${ans}" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 1 ;;
      esac
    fi
    nix --extra-experimental-features "nix-command flakes" run --impure \
      github:nix-community/disko -- \
      --mode disko "${ROOT}/targets/${TARGET}/disks.nix"

    echo
    echo "Post-disko validation:"
    if command -v zpool >/dev/null 2>&1; then
      zpool import -N rpool >/dev/null 2>&1 || true
      zpool get -H bootfs rpool || true
      zfs list -r rpool || true
    else
      echo "  zpool not found; skipping ZFS validation."
    fi
    ;;
  install)
    validate_hardware
    export BOWENOS_HARDWARE_CONFIG="${HARDWARE_FILE}"
    nixos-install --impure --flake "${ROOT}#${TARGET}"
    if command -v zpool >/dev/null 2>&1; then
      echo "Exporting rpool before reboot..."
      zpool export rpool || true
    fi
    ;;
  switch)
    validate_hardware
    export BOWENOS_HARDWARE_CONFIG="${HARDWARE_FILE}"
    sudo nixos-rebuild switch --impure --flake "${ROOT}#${TARGET}"
    ;;
  iscsi-check)
    fail=0
    shopt -s nullglob
    for f in "${ROOT}"/modules/services/iscsi/targets/*.nix; do
      echo "Checking ${f}"
      paths="$(grep -oE 'backing[[:space:]]*=[[:space:]]*"[^"]+"' "${f}" | sed -E 's/.*"([^"]+)".*/\1/')"
      if [[ -z "${paths}" ]]; then
        echo "  (no backing paths found)"
        continue
      fi
      for p in ${paths}; do
        if [[ ! -e "${p}" ]]; then
          echo "  ❌ Missing: ${p}"
          fail=1
        else
          echo "  ✅ Found:   ${p}"
        fi
      done
    done
    exit ${fail}
    ;;
  hardware-scan)
    rm -rf /tmp/hardware
    mkdir -p /tmp/hardware
    nixos-generate-config --root /tmp/hardware
    cp /tmp/hardware/etc/nixos/hardware-configuration.nix "${ROOT}/hardware-configuration.nix"
    echo "Wrote ${ROOT}/hardware-configuration.nix"
    validate_hardware
    ;;
  repair)
    validate_hardware
    export BOWENOS_HARDWARE_CONFIG="/etc/nixos/hardware-configuration.nix"
    if ! mountpoint -q /mnt; then
      echo "/mnt is not a mountpoint. Mount rpool/root at /mnt first." >&2
      exit 2
    fi
    nixos-enter --root /mnt -- \
      env BOWENOS_HARDWARE_CONFIG="${BOWENOS_HARDWARE_CONFIG}" \
      nixos-rebuild switch --impure --flake "/etc/nixos#${TARGET}"
    ;;
  *)
    usage
    exit 2
    ;;
esac
