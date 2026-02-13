{ ... }:
{
  imports = [
    ./bowenos-tools-import.nix
  ];

  services.bcrail = {
    enable = true;
    # package = pkgs.bcrail; # default
    stateDir = "/var/lib/bcrail";
    configDir = "/etc/bcrail";

    network.bridge = "incusbr0";
    storage.pool = "zfs-ssd";

    remoteUser = "vancouver";
    stateDevice = "/dev/sdb"; # or e.g. "/dev/vdb"

    setupOnBoot = false;
  };
}
