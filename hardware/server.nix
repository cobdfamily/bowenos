{ ... }:
{
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  boot.shell_on_fail = true;
}
