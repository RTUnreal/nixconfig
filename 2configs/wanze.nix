{...}: {
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
    ];
    config = {};
  };
}
