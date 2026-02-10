{ ... }:
{
  systemd.services.no-emergency = {
    description = "Reboot immediately if emergency mode is reached";
    wantedBy = [ "emergency.target" "rescue.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/systemctl reboot --force --no-block";
    };
  };
}
