{ ... }:
{
  bowenos.storage.diskMode = "mirror";

  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];
}
