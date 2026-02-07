{ lib, config, ... }:
let cfg = config.bowenos.lanBridge;
in {
  options.bowenos.lanBridge = {
    enable = lib.mkEnableOption "Create a LAN bridge for Incus instances";
    bridgeName = lib.mkOption { type = lib.types.str; default = "br0"; };
  };

  config = lib.mkIf cfg.enable {
    networking.useNetworkd = true;
    systemd.network.enable = true;

    systemd.network.netdevs."10-${cfg.bridgeName}" = {
      netdevConfig = { Name = cfg.bridgeName; Kind = "bridge"; };
    };

    systemd.network.networks."10-uplink-en" = {
      matchConfig.Name = "en*";
      networkConfig = { Bridge = cfg.bridgeName; DHCP = "no"; };
    };

    systemd.network.networks."10-${cfg.bridgeName}" = {
      matchConfig.Name = cfg.bridgeName;
      networkConfig.DHCP = "yes";
    };
  };
}
