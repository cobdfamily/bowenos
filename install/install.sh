#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${HOST:-}"
INVENTORY_ROOT="${ROOT}/installer/flakes/inventory"
HARDWARE_FILE="${ROOT}/hardware-configuration.nix"

TARGET="${TARGET:-computeplusstorage}"
CMD="${1:-}"

usage() {
  cat <<'USAGE'
Usage: install.sh <command>

Commands:
  show-env     Print key environment values
  iso          Build the bootstrap ISO
  setup        Create /tmp/bowenos inventory for a new host
  disko        Partition + create mirrored rpool (destructive)
  install      Run nixos-install for TARGET
  switch       Run nixos-rebuild switch for TARGET
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

set_local_nix_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp
  tmp="$(mktemp)"

  awk -v k="${key}" -v v="${value}" '
    BEGIN { found = 0; }
    $0 ~ "^[[:space:]]*" k "[[:space:]]*=" {
      print "  " k " = " v ";"
      found = 1
      next
    }
    { print }
    END {
      if (!found) {
        # Insert before last } if present, otherwise append.
        if (NR > 0) {
          # handled by second pass
        }
      }
    }
  ' "${file}" > "${tmp}"

  if ! grep -q "^[[:space:]]*${key}[[:space:]]*=" "${tmp}"; then
    awk -v k="${key}" -v v="${value}" '
      BEGIN { inserted = 0; }
      /}[[:space:]]*$/ && !inserted {
        print "  " k " = " v ";"
        inserted = 1
      }
      { print }
      END {
        if (!inserted) {
          print "  " k " = " v ";"
        }
      }
    ' "${tmp}" > "${tmp}.2"
    mv "${tmp}.2" "${tmp}"
  fi

  mv "${tmp}" "${file}"
}

select_disk_by_id() {
  local prompt="$1"
  local -n _choices=$2
  local -n _selected=$3

  while true; do
    echo "${prompt}"
    local i=1
    for d in "${_choices[@]}"; do
      echo "  ${i}) ${d}"
      i=$((i + 1))
    done
    read -r -p "Select disk number: " idx
    if [[ "${idx}" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#_choices[@]} )); then
      local choice="${_choices[$((idx-1))]}"
      # ensure not already selected
      for s in "${_selected[@]}"; do
        if [[ "${s}" == "${choice}" ]]; then
          echo "Disk already selected. Choose a different disk."
          choice=""
          break
        fi
      done
      if [[ -n "${choice}" ]]; then
        _selected+=("${choice}")
        break
      fi
    else
      echo "Invalid selection."
    fi
  done
}

case "${CMD}" in
  show-env)
    echo "HOST=${HOST:-}"
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
  setup)
    read -r -p "Hostname: " HOSTNAME
    if [[ -z "${HOSTNAME}" ]]; then
      echo "Hostname is required." >&2
      exit 2
    fi

    rm -rf /tmp/bowenos
    mkdir -p /tmp/bowenos

    # Copy inventory flake
    cp "${INVENTORY_ROOT}/flake.nix" /tmp/bowenos/flake.nix
    if [[ -f "${INVENTORY_ROOT}/flake.lock" ]]; then
      cp "${INVENTORY_ROOT}/flake.lock" /tmp/bowenos/flake.lock
    fi

    # Copy example host
    mkdir -p "/tmp/bowenos/hosts/${HOSTNAME}"
    cp "${INVENTORY_ROOT}/hosts/example/local.nix" "/tmp/bowenos/hosts/${HOSTNAME}/local.nix"

    # Disk mode
    read -r -p "Disk mode (mirror/single) [mirror]: " DISK_MODE
    DISK_MODE="${DISK_MODE:-mirror}"
    if [[ "${DISK_MODE}" != "mirror" && "${DISK_MODE}" != "single" ]]; then
      echo "Invalid disk mode." >&2
      exit 2
    fi
    set_local_nix_value "/tmp/bowenos/hosts/${HOSTNAME}/local.nix" "diskMode" "\"${DISK_MODE}\""

    # Admin user + SSH key
    read -r -p "Admin username [admin]: " ADMIN_USER
    ADMIN_USER="${ADMIN_USER:-admin}"
    set_local_nix_value "/tmp/bowenos/hosts/${HOSTNAME}/local.nix" "adminUser" "\"${ADMIN_USER}\""

    read -r -p "SSH public key: " SSH_KEY
    if [[ -z "${SSH_KEY}" ]]; then
      echo "SSH public key is required." >&2
      exit 2
    fi
    set_local_nix_value "/tmp/bowenos/hosts/${HOSTNAME}/local.nix" "sshPubKey" "\"${SSH_KEY}\""

    # Disk selection menu
    mapfile -t disks < <(ls -1 /dev/disk/by-id | grep -v -- '-part' | sort -u)
    if [[ ${#disks[@]} -eq 0 ]]; then
      echo "No disks found in /dev/disk/by-id." >&2
      exit 2
    fi

    selected=()
    select_disk_by_id "Select BOOTA_BYID:" disks selected
    if [[ "${DISK_MODE}" == "mirror" ]]; then
      select_disk_by_id "Select BOOTB_BYID:" disks selected
    fi

    set_local_nix_value "/tmp/bowenos/hosts/${HOSTNAME}/local.nix" "bootaById" "\"${selected[0]}\""
    if [[ "${DISK_MODE}" == "mirror" ]]; then
      set_local_nix_value "/tmp/bowenos/hosts/${HOSTNAME}/local.nix" "bootbById" "\"${selected[1]}\""
    else
      set_local_nix_value "/tmp/bowenos/hosts/${HOSTNAME}/local.nix" "bootbById" "\"\""
    fi

    # Hardware scan
    rm -rf /tmp/hardware
    mkdir -p /tmp/hardware
    nixos-generate-config --root /tmp/hardware
    cp /tmp/hardware/etc/nixos/hardware-configuration.nix "/tmp/bowenos/hosts/${HOSTNAME}/hardware-configuration.nix"

    echo "Inventory written to /tmp/bowenos/hosts/${HOSTNAME}"
    ;;
  disko)
    if [[ -n "${HOST}" ]]; then
      TARGET="$(nix eval --raw "${INVENTORY_ROOT}#hostInfo.${HOST}.target")"
      HARDWARE_FILE="${INVENTORY_ROOT}/hosts/${HOST}/hardware-configuration.nix"
      if [[ -z "${BOOTA_BYID:-}" ]]; then
        BOOTA_BYID="$(nix eval --raw "${INVENTORY_ROOT}#hosts.${HOST}.bootaById")"
      fi
      if [[ -z "${BOOTB_BYID:-}" ]]; then
        BOOTB_BYID="$(nix eval --raw "${INVENTORY_ROOT}#hosts.${HOST}.bootbById")"
      fi
    fi
    if [[ -z "${BOOTA_BYID:-}" || -z "${BOOTB_BYID:-}" ]]; then
      echo "Set BOOTA_BYID and BOOTB_BYID or add bootaById/bootbById to hosts/${HOST}/local.nix." >&2
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
    if [[ -n "${HOST}" ]]; then
      HARDWARE_FILE="${INVENTORY_ROOT}/hosts/${HOST}/hardware-configuration.nix"
    fi
    validate_hardware
    export BOWENOS_HARDWARE_CONFIG="${HARDWARE_FILE}"
    if [[ -n "${HOST}" ]]; then
      nixos-install --impure --flake "${INVENTORY_ROOT}#${HOST}"
    else
      nixos-install --impure --flake "${ROOT}#${TARGET}"
    fi
    if command -v zpool >/dev/null 2>&1; then
      echo "Exporting rpool before reboot..."
      zpool export rpool || true
    fi
    ;;
  switch)
    if [[ -n "${HOST}" ]]; then
      HARDWARE_FILE="${INVENTORY_ROOT}/hosts/${HOST}/hardware-configuration.nix"
    fi
    validate_hardware
    export BOWENOS_HARDWARE_CONFIG="${HARDWARE_FILE}"
    if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
      export BOWENOS_HARDWARE_CONFIG="/etc/nixos/hardware-configuration.nix"
    fi
    if [[ -n "${HOST}" ]]; then
      sudo env BOWENOS_HARDWARE_CONFIG="${BOWENOS_HARDWARE_CONFIG}" \
        nixos-rebuild switch --impure --flake "${INVENTORY_ROOT}#${HOST}"
    else
      sudo env BOWENOS_HARDWARE_CONFIG="${BOWENOS_HARDWARE_CONFIG}" \
        nixos-rebuild switch --impure --flake "${ROOT}#${TARGET}"
    fi
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
    if [[ -n "${HOST}" ]]; then
      mkdir -p "${INVENTORY_ROOT}/hosts/${HOST}"
      cp /tmp/hardware/etc/nixos/hardware-configuration.nix "${INVENTORY_ROOT}/hosts/${HOST}/hardware-configuration.nix"
      HARDWARE_FILE="${INVENTORY_ROOT}/hosts/${HOST}/hardware-configuration.nix"
    else
      cp /tmp/hardware/etc/nixos/hardware-configuration.nix "${ROOT}/hardware-configuration.nix"
      HARDWARE_FILE="${ROOT}/hardware-configuration.nix"
    fi
    echo "Wrote ${HARDWARE_FILE}"
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
