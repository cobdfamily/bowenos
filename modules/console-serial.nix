{ ... }:
{
  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
    terminal_input serial
    terminal_output serial
  '';

  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

}
