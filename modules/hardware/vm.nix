{ modulesPath, ... }:
{
  imports = [
    ../base.nix
    ../base-packages.nix
    ../users-ssh.nix
    ../storage-tmpfs-root.nix
    ../storage-ext4.nix
    ../persistence.nix
    ../console-serial.nix
    ../boot.nix
    ../system-emergency.nix
    "${modulesPath}/virtualisation/lxc-instance-common.nix"

    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  # CPU hotplug
  services.udev.extraRules = ''
    SUBSYSTEM=="cpu", CONST{arch}=="x86-64", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
  '';

  virtualisation.incus.agent.enable = lib.mkDefault true;

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-enp5s0" = {
      matchConfig.Name = "enp5s0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}