# derived from: https://github.com/felschr/nixos-config/blob/1043b12ec969fbc62392b27836feafa572e4bd4b/services/home-assistant/default.nix
{ lib, ... }:
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      # List of components required to complete the onboarding
      "default_config"
      "met"
      "esphome"

      # added modules
      "dwd_weather_warnings"
      "mobile_app"

      "assist_pipeline"
      "wyoming"
      "wake_word"
    ];
    config = {
      mobile_app = { };
      assist_pipeline = { };
      wake_word = { };
    };
  };

  services.wyoming.piper = {
    servers = {
      "de" = {
        enable = true;
        # see https://github.com/rhasspy/rhasspy3/blob/master/programs/tts/piper/script/download.py
        voice = "de-eva_k-x-low"; # "en-gb-southern_english_female-low";
        uri = "tcp://0.0.0.0:10200";
        speaker = 0;
      };
    };
  };

  services.wyoming.faster-whisper = {
    servers = {
      "en" = {
        enable = true;
        # see https://github.com/rhasspy/rhasspy3/blob/master/programs/asr/faster-whisper/script/download.py
        model = "tiny-int8";
        language = "de";
        uri = "tcp://0.0.0.0:10300";
        device = "cpu";
      };
    };
  };

  # needs access to /proc/cpuinfo
  systemd.services."wyoming-faster-whisper-de".serviceConfig.ProcSubset = lib.mkForce "all";
}
