{ ... }:
{
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
    "rd.shell"
    "rd.break"
  ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
}
