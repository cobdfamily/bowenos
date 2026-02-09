{ ... }:
{
  fileSystems."/persist".neededForBoot = true;
  boot.tmp.useTmpfs = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/incus"
      "/var/lib/nixos"
      "/opt/cprail"
      "/etc/ssh"
      "/var/lib/systemd/coredump"
    ];
    files = [
      "/etc/machine-id"
      "/etc/hostid"
      "/var/lib/dbus/machine-id"
      "/etc/adjtime"
    ];
  };
}
