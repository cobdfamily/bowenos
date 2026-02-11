{ ... }:
{
  imports = [
    ../../modules/hardware/server.nix
    ../../modules/lan-bridge.nix
    ../../modules/services/incus.nix
  ];

  bowenos.lanBridge = {
    enable = true;
    bridgeName = "br0";
  };

  system.stateVersion = "25.11";
}
