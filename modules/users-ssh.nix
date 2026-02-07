{ lib, pkgs, ... }:
let
  get = name: def: let v = builtins.getEnv name; in if v == "" then def else v;

  adminUser = get "ADMIN_USER" "admin";

  keyFromVar = builtins.getEnv "SSH_PUBKEY";
  keyFile = builtins.getEnv "SSH_PUBKEY_FILE";
  keyFromFile = if keyFile == "" then "" else builtins.readFile keyFile;

  sshKeyRaw = if keyFromVar != "" then keyFromVar else keyFromFile;
  sshKey = lib.strings.trimString sshKeyRaw;

  haveKey = sshKey != "";
  allowNoKey = (get "ALLOW_NO_SSH_KEY" "false") == "true";

  sudoNeedsPassword = (get "SUDO_NEEDS_PASSWORD" "false") == "true";
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

  # Keep it predictable: NixOS manages users; you can later set hashedPassword manually if you want.
  users.mutableUsers = true;

  users.users.${adminUser} = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [
      "wheel"
      "incus-admin"
      "systemd-journal"
    ];
    openssh.authorizedKeys.keys = lib.optionals haveKey [ sshKey ];
  };

  security.sudo.wheelNeedsPassword = sudoNeedsPassword;

  assertions = [
    {
      assertion = haveKey || allowNoKey;
      message = "No SSH key provided. Set SSH_PUBKEY or SSH_PUBKEY_FILE (or set ALLOW_NO_SSH_KEY=true for console-only bootstrap).";
    }
  ];
}
