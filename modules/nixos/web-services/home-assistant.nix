{ config, lib, ... }:
let
  cfg = config.custom.web-services.home-assistant;
  dataDir = config.services.home-assistant.configDir;
in
{
  options.custom.web-services.home-assistant = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8123;
    };
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
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
          server_port = cfg.port;
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
      services = {
        caddy.virtualHosts.${cfg.domain} = {
          inherit (cfg) port;
          allowedGroups = [
            "client"
            "agent"
          ];
        };

        restic.backups.home-assistant = lib.mkIf cfg.doBackups {
          conflictingService = "home-assistant.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];

      meta.sites.${cfg.domain} = {
        title = "Home Assistant";
        icon = "sh:home-assistant";
      };
    };
  };
}
