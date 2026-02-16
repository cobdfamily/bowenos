{ config, ... }:
{
  virtualisation.docker.enable = true;

  virtualisation.docker.daemon.settings = {
    iptables = true;
    ip6tables = true; # optional
  };

  networking.firewall.trustedInterfaces = [ "docker0" ];

  users.users.${config.bowenos.users.adminUser}.extraGroups = [ "docker" ];

  environment.persistence."/persist".directories = [
    "/var/lib/docker"
  ];
}
