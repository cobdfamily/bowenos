{ ... }:
{
  imports = [
    ../../modules/hardware/server.nix
    ../../modules/lan-bridge.nix
    ../../modules/services/incus.nix
    ../../modules/services/bcrail.nix
  ];

  system.stateVersion = "25.11";
}
