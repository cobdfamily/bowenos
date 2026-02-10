{ lib, pkgs, ... }:
{
  # Use systemd in initrd so emergency handling can run before root is mounted.
  boot.initrd.systemd.enable = true;

  # Initrd: force reboot if emergency is reached.
  boot.initrd.systemd.services.no-emergency = {
    description = "Reboot immediately if initrd emergency mode is reached";
    wantedBy = [ "emergency.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/bin/systemctl reboot --force --no-block";
    };
  };

  # Main system: force reboot if emergency or rescue is reached.
  systemd.services.no-emergency = {
    description = "Reboot immediately if emergency/rescue mode is reached";
    wantedBy = [ "emergency.target" "rescue.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reboot --force --no-block";
    };
  };
}
