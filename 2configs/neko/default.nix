{ selflib, ... }:
{
  #hardware.nvidia-container-toolkit.enable = true;
  virtualisation.oci-containers.containers = {
    neko = {
      #image = "m1k1o/neko:firefox";
      image = "ghcr.io/m1k1o/neko/intel-firefox:latest";
      autoStart = true;
      extraOptions = [
        "--pull=newer"
        "-l=homepage.group=Services"
        "-l=homepage.name=Neko"
        "-l=homepage.icon=neko.svg"
        "-l=homepage.href=http://neko.rtinf.net:3023"
        "-l=homepage.description=Remote browser service with Firefox"
      ];
      devices = [ "/dev/dri:/dev/dri" ];
      ports = [
        "3023:8080"
        "52000-52100:52000-52100/udp"
      ];
      environment = {
        NEKO_SCREEN = "1280x720@30";
        #NEKO_SCREEN = "1920x1080@30";
        NEKO_SERVER_PROXY = "true";
        NEKO_WEBRTC_EPR = "52000-52100";
        NEKO_WEBRTC_ICELITE = "0";
        NEKO_WEBRTC_NAT1TO1 = "192.168.0.101";
        NEKO_MEMBER_PROVIDER = "multiuser";
        NEKO_SESSION_CONTROL_PROTECTION = "true";
        NEKO_CAPTURE_BROADCAST_URL = "rtmp://${selflib.homevpn.hosts.safe.ip}/live/neko";

        #NVIDIA_VISIBLE_DEVICES = "all";
        #NVIDIA_DRIVER_CAPABILITIES = "all";
        # taken from: https://github.com/jameskitt616/vrchat_streaming/blob/master/compose.yaml
        NEKO_CAPTURE_VIDEO_CODEC = "h264";
        NEKO_CAPTURE_VIDEO_PIPELINE = ''
          ximagesrc display-name={display} show-pointer=true use-damage=false !
          videoconvert !
          videorate !
          videoscale !
          video/x-raw,width=1920,height=1080,framerate=30/1 !
          vaapih264enc rate-control=cbr bitrate=6144 keyframe-period=30 !
          h264parse !
          queue !

          pulsesrc device=audio_output.monitor !
          audioconvert !
          audioresample !
          audio/x-raw,channels=2 !
          voaacenc bitrate=320000 !
          aacparse !
          queue !
          mux.
        '';
        NEKO_CAPTURE_BROADCAST_PIPELINE = ''
          ximagesrc display-name={display} show-pointer=true use-damage=false !
          queue max-size-buffers=2 leaky=downstream !
          videoconvert !
          videorate !
          videoscale !
          video/x-raw,width=1920,height=1080,framerate=30/1 !
          vaapih264enc rate-control=cbr bitrate=6144 keyframe-period=30 !
          h264parse !
          queue !
          mpegtsmux name=mux alignment=7 !
          udpsink host=mediamtx port=1234 sync=false buffer-size=524288

          pulsesrc device=audio_output.monitor !
          queue !
          audioconvert !
          audioresample !
          audio/x-raw,channels=2 !
          voaacenc bitrate=320000 !
          aacparse !
          queue !
          mux.
        '';
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
