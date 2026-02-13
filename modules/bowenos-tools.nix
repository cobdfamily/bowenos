{ ... }:
{
  imports = [
    ./imports/bowenos-tools-import.nix
  ];

  services.bowenos-tools = {
    enable = true;
  };
}
