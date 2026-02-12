{ pkgs, ... }:
{
  # Optional host users file.
  #
  # This file is imported automatically if it exists at:
  #   flakes/inventory/hosts/<HOST>/users.nix
  #
  # Available fields you can use (standard NixOS users options):
  # - users.users.<name>.isNormalUser
  # - users.users.<name>.shell
  # - users.users.<name>.extraGroups
  # - users.users.<name>.openssh.authorizedKeys.keys
  # - users.users.<name>.initialPassword
  # - users.users.<name>.hashedPassword
  # - users.users.<name>.packages
  # - users.groups.<name>
  # - security.sudo.wheelNeedsPassword
  #
  # Example extra user:
  users.users.alice = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "wheel" "incus-admin" "systemd-journal" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAExampleKeyHere alice@example"
    ];
  };

  # Example service user:
  users.users.backup = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "backup" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAExampleKeyHere backup@example"
    ];
  };
  users.groups.backup = {};
}
