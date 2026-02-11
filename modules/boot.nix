{ ... }:
{
  imports = [ ./boot-grub.nix ];
  boot.loader.timeout = 30;
}