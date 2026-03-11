{ selflib, ... }:
{
  #hardware.nvidia-container-toolkit.enable = true;
  virtualisation.oci-containers.containers = {
    neko = {
      image = "m1k1o/neko:firefox";
      autoStart = true;
      extraOptions = [
        "--pull=newer"
        "-l=homepage.group=Services"
        "-l=homepage.name=Neko"
        "-l=homepage.icon=neko.svg"
        "-l=homepage.href=http://neko.rtinf.net:3023"
        "-l=homepage.description=Remote browser service with Firefox"
      ];
      #devices = [ "nvidia.com/gpu=all" ];
      ports = [
        "3023:8080"
        "52000-52100:52000-52100/udp"
      ];
      environment = {
        NEKO_SCREEN = "1280x720@30";
        #NEKO_SCREEN = "1920x1080@30";
        NEKO_EPR = "52000-52100";
        NEKO_ICELITE = "0";
        NEKO_SERVER_PROXY = "true";
        NEKO_NAT1TO1 = "192.168.0.101";
        NEKO_CAPTURE_BROADCAST_URL = "rtmp://${selflib.homevpn.hosts.safe.ip}/live/neko";

        #NVIDIA_VISIBLE_DEVICES = "all";
        #NVIDIA_DRIVER_CAPABILITIES = "all";
        #NEKO_CAPTURE_VIDEO_CODEC = "h264";
        #NEKO_CAPTURE_VIDEO_PIPELINE = ''
        #  ximagesrc display-name={display} show-pointer=true use-damage=false
        #  ! video/x-raw,framerate=25/1
        #  ! videoconvert ! queue
        #  ! video/x-raw,format=NV12
        #  ! nvh264enc
        #    name=encoder
        #    preset=2
        #    gop-size=25
        #    spatial-aq=true
        #    temporal-aq=true
        #    bitrate=4096
        #    vbv-buffer-size=4096
        #    rc-mode=6
        #  ! h264parse config-interval=-1
        #  ! video/x-h264,stream-format=byte-stream
        #  ! appsink name=appsink
        #'';
      };
      environmentFiles = [ "/var/lib/neko/.env" ];
    };
  };
  networking.firewall = {
    allowedTCPPorts = [ 3023 ];
    allowedUDPPortRanges = [
      {
        from = 52000;
        to = 52100;
      }
    ];
  };
}
