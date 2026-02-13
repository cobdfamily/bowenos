{ ... }:
{
  imports = [
    ./bcrail-import.nix
  ];

  services.bcrail.enable = true;
}