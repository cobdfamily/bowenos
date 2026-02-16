{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
    ../base.nix
    ../base-packages.nix
    ../users-ssh.nix
    ../storage-tmpfs-root.nix
    ../storage-ext4.nix
    ../persistence.nix
    ../console-serial.nix
    ../boot.nix
    ../system-emergency.nix
  ];

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