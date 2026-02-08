{ lib, pkgs, config, ... }:
let
  cfg = config.bowenos.users;
  sshKey = lib.strings.removeSuffix "\r" (lib.strings.removeSuffix "\n" cfg.sshPubKey);
  haveKey = sshKey != "";
in
{
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
    PubkeyAuthentication = true;
    X11Forwarding = false;
    AllowTcpForwarding = "no";
  };

  # Default to immutable users for reproducibility; set MUTABLE_USERS=true to opt in.
  users.mutableUsers = cfg.mutableUsers;

  users.users.${cfg.adminUser} = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [
      "wheel"
      "incus-admin"
      "systemd-journal"
    ];
    openssh.authorizedKeys.keys = lib.optionals haveKey [ sshKey ];
  };

  security.sudo.wheelNeedsPassword = cfg.sudoNeedsPassword;

  assertions = [
    {
      assertion = haveKey || cfg.allowNoKey;
      message = "No SSH key provided. Set SSH_PUBKEY or SSH_PUBKEY_FILE (or set ALLOW_NO_SSH_KEY=true for console-only bootstrap).";
    }
  ];
}
