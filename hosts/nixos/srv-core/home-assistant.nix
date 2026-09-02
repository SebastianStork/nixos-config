{ config, ... }:
let
  domain = "home-assistant.${config.networking.domain}";
  dataDir = config.services.home-assistant.configDir;
in
{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "zha"
      "google_translate"
    ];
    config = {
      default_config = { };
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
      http = {
        server_host = [ "127.0.0.1" ];
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "f ${dataDir}/automations.yaml 0600 hass hass - []"
    "f ${dataDir}/scripts.yaml 0600 hass hass - {}"
    "f ${dataDir}/scenes.yaml 0600 hass hass - []"
  ];

  custom = {
    services.caddy.virtualHosts.${domain}.port = config.services.home-assistant.config.http.server_port;

    persistence.directories = [ dataDir ];

    meta.sites.${domain} = {
      title = "Home Assistant";
      icon = "sh:home-assistant";
    };
  };
}
