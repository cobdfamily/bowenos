{
  iqn = "iqn.2026-02.local.computeplusstorage:vmstore";
  luns = [ { name = "vmstore"; backing = "/dev/zvol/tank/vmstore"; } ];
  acls = [ { initiator = "iqn.1993-08.org.debian:01:client1"; } ];
}
