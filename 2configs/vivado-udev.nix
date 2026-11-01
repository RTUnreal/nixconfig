{ pkgs, lib, ... }: {
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", MODE="666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1443", MODE="666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="03fd", MODE="666"
    # Unbind default ftdi_sio kernel driver
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403" \
    RUN+="${lib.getExe pkgs.bash} -c 'echo -n $kernel > /sys/bus/usb/drivers/ftdi_sio/unbind'"
  '';
}
