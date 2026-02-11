{ lib, pkgs, ... }:
{
  fileSystems."/persist".neededForBoot = true;
  boot.tmp.useTmpfs = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/bowenos"
      "/var/lib/incus/cluster"
      "/var/lib/incus/database"
      "/var/lib/incus/devices"
      "/var/lib/incus/state"
      "/var/lib/nixos"
      "/var/log"
    ];
    files = [
      "/etc/adjtime"
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ecdsa_key"
      "/etc/ssh/ssh_host_ecdsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/var/lib/incus/server.crt"
      "/var/lib/incus/server.key"
      "/var/lib/dbus/machine-id"
    ];
  };
}
