{
  config,
  inputs,
  self,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.home-assistant;
  dataDir = config.services.home-assistant.configDir;
  zigbee2mqttDataDir = config.services.zigbee2mqtt.dataDir;
  mosquittoDataDir = config.services.mosquitto.dataDir;
in
{
  disabledModules = [ "services/home-automation/home-assistant.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/home-automation/home-assistant.nix"
  ];

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
    zigbee2mqtt = {
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 6836;
      };
      mqttPort = lib.mkOption {
        type = lib.types.port;
        default = 1883;
      };
      serialPort = lib.mkOption {
        type = lib.types.nonEmptyStr;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.zigbee2mqtt.domain;
      message = self.lib.mkUnprotectedMessage "Zigbee2MQTT";
    };

    services = {
      home-assistant = {
        enable = true;
        package = pkgs-unstable.home-assistant;
        extraComponents = [
          "google_translate"
          "mqtt"
        ];
        config = {
          default_config = { };
          automation = "!include automations.yaml";
          script = "!include scripts.yaml";
          scene = "!include scenes.yaml";
        };
      };

      mosquitto = {
        enable = true;
        listeners = lib.singleton {
          address = "127.0.0.1";
          port = cfg.zigbee2mqtt.mqttPort;
          omitPasswordAuth = true;
        };
      };

      zigbee2mqtt = {
        enable = true;
        settings = {
          homeassistant.enabled = true;
          mqtt.server = "mqtt://127.0.0.1:${lib.toString cfg.zigbee2mqtt.mqttPort}";
          serial = {
            port = cfg.zigbee2mqtt.serialPort;
            adapter = "ember";
          };
          frontend = {
            enabled = true;
            host = "127.0.0.1";
            inherit (cfg.zigbee2mqtt) port;
          };
        };
      };
    };

    systemd.services.zigbee2mqtt = {
      after = [ "mosquitto.service" ];
      requires = [ "mosquitto.service" ];
    };

    systemd.tmpfiles.rules = [
      "f ${dataDir}/automations.yaml 0600 hass hass - []"
      "f ${dataDir}/scripts.yaml 0600 hass hass - {}"
      "f ${dataDir}/scenes.yaml 0600 hass hass - []"
    ];

    custom = {
      services = {
        caddy.virtualHosts = {
          ${cfg.domain} = {
            inherit (cfg) port;
            allowedGroups = [
              "client"
              "agent"
            ];
          };
          ${cfg.zigbee2mqtt.domain}.port = cfg.zigbee2mqtt.port;
        };

        restic.backups = {
          home-assistant = lib.mkIf cfg.doBackups {
            conflictingService = "home-assistant.service";
            paths = [ dataDir ];
          };
          zigbee2mqtt = lib.mkIf cfg.doBackups {
            conflictingService = "zigbee2mqtt.service";
            paths = [ zigbee2mqttDataDir ];
          };
        };
      };

      persistence.directories = [
        dataDir
        zigbee2mqttDataDir
        mosquittoDataDir
      ];

      meta.sites = {
        ${cfg.domain} = {
          title = "Home Assistant";
          icon = "sh:home-assistant";
        };
        ${cfg.zigbee2mqtt.domain} = {
          title = "Zigbee2MQTT";
          icon = "sh:zigbee2mqtt";
        };
      };
    };
  };
}
