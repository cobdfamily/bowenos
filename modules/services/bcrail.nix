{ inputs, pkgs, ... }:
{
  imports = [
    inputs.bcrail.nixosModules.default
  ];

  services.bcrail = {
    enable = true;
    package = inputs.bcrail.packages.${pkgs.system}.bcrail;

    stateDir = "/var/lib/bcrail";
    configDir = "/etc/bcrail";

    network.bridge = "incusbr0";
    storage.pool = "zfs-ssd";

    ignitionFile = inputs.bcrail + "/etc/bcrail/ignition.json";
    locomotiveEnvFile = inputs.bcrail + "/etc/bcrail/locomotive.env";

    setupOnBoot = false;
  };
}
