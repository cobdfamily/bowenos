set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Choose role at runtime: TARGET=compute or TARGET=computeplusstorage
TARGET := "${TARGET:-computeplusstorage}"

default:
	@just --list

show-env:
	@echo "TARGET=${TARGET}"
	@echo "ROLE=${ROLE:-}"
	@echo "HOSTNAME=${HOSTNAME:-}"
	@echo "HOSTID=${HOSTID:-}"
	@echo "TIMEZONE=${TIMEZONE:-}"
	@echo "LOCALE=${LOCALE:-}"
	@echo "BOOTA_BYID=${BOOTA_BYID:-}"
	@echo "BOOTB_BYID=${BOOTB_BYID:-}"
	@echo "BOOTB_DISK_PATH=${BOOTB_DISK_PATH:-}"
	@echo "ADMIN_USER=${ADMIN_USER:-}"
	@echo "SSH_PUBKEY set? $([[ -n ${SSH_PUBKEY:-} ]] && echo yes || echo no)"
	@echo "SSH_PUBKEY_FILE=${SSH_PUBKEY_FILE:-}"
	@echo "SUDO_NEEDS_PASSWORD=${SUDO_NEEDS_PASSWORD:-}"
	@echo "ALLOW_NO_SSH_KEY=${ALLOW_NO_SSH_KEY:-}"

disko:
	@if [[ -z "${BOOTA_BYID:-}" || -z "${BOOTB_BYID:-}" ]]; then 	  echo "Set BOOTA_BYID and BOOTB_BYID in .env or env."; exit 2; fi
	@if [[ "${FORCE:-0}" != "1" ]]; then 	  echo "⚠️  About to WIPE and repartition:"; 	  echo "    BOOTA_BYID=${BOOTA_BYID}"; 	  echo "    BOOTB_BYID=${BOOTB_BYID}"; 	  read -r -p "Continue? (y/N) " ans; 	  case "$$ans" in [yY]|[yY][eE][sS]) ;; *) echo "Aborted."; exit 1 ;; esac; 	fi
	@nix --extra-experimental-features "nix-command flakes" run --impure 	  github:nix-community/disko -- 	  --mode disko ./roles/${TARGET}/disks.nix

install:
	@nixos-install --impure --flake .#${TARGET}

switch:
	@sudo nixos-rebuild switch --impure --flake .#${TARGET}

iscsi-check:
	@fail=0; 	shopt -s nullglob; 	for f in modules/iscsi/targets/*.nix; do 	  echo "Checking $$f"; 	  paths=$$(grep -oE 'backing[[:space:]]*=[[:space:]]*"[^"]+"' "$$f" | sed -E 's/.*"([^"]+)".*/\1/'); 	  if [[ -z "$$paths" ]]; then 	    echo "  (no backing paths found)"; 	    continue; 	  fi; 	  for p in $$paths; do 	    if [[ ! -e "$$p" ]]; then 	      echo "  ❌ Missing: $$p"; 	      fail=1; 	    else 	      echo "  ✅ Found:   $$p"; 	    fi; 	  done; 	done; 	exit $$fail
