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
    ];
    files = [
      "/etc/machine-id"
      "/var/lib/dbus/machine-id"
      "/etc/adjtime"
    ];
  };
}
