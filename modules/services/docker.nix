{ config, ... }:
{
  virtualisation.docker.enable = true;

  users.users.${config.bowenos.users.adminUser}.extraGroups = [ "docker" ];

  environment.persistence."/persist".directories = [
    "/var/lib/docker"
  ];
}
