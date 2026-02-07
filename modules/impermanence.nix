{ ... }:
{
  fileSystems."/persist".neededForBoot = true;
  boot.tmp.useTmpfs = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/incus"
      "/opt/cprail"
    ];
    files = [
      "/etc/machine-id"
      "/etc/adjtime"
    ];
  };
}
