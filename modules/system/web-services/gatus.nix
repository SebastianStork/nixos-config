{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.gatus;
  dataDir = "/var/lib/gatus";
in
{
  options.custom.web-services.gatus = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
    ntfyUrl = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "https://${config.custom.web-services.ntfy.domain}";
    };
    generateDefaultEndpoints = lib.mkEnableOption "";
    endpoints = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "" // {
                default = true;
              };
              name = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = name;
              };
              group = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "";
              };
              protocol = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "https";
              };
              domain = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "";
              };
              path = lib.mkOption {
                type = lib.types.str;
                default = "";
              };
              interval = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "30s";
              };
              extraConditions = lib.mkOption {
                type = lib.types.listOf lib.types.nonEmptyStr;
                default = [ ];
              };
              enableAlerts = lib.mkEnableOption "" // {
                default = true;
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets."healthchecks/ping-key" = { };
      templates."gatus.env" = {
        content = "HEALTHCHECKS_PING_KEY=${config.sops.placeholder."healthchecks/ping-key"}";
        owner = config.users.users.gatus.name;
        restartUnits = [ "gatus.service" ];
      };
    };

    users = {
      users.gatus = {
        isSystemUser = true;
        group = config.users.groups.gatus.name;
      };
      groups.gatus = { };
    };

    systemd.services.gatus.serviceConfig = {
      DynamicUser = lib.mkForce false;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      RemoveIPC = true;
    };

    services.gatus = {
      enable = true;
      environmentFile = config.sops.templates."gatus.env".path;

      settings = {
        web = {
          address = "localhost";
          inherit (cfg) port;
        };
        storage = {
          type = "sqlite";
          path = "${dataDir}/data.db";
        };
        connectivity.checker.target = "1.1.1.1:53"; # Cloudflare DNS
        alerting.ntfy = {
          topic = "uptime";
          url = cfg.ntfyUrl;
          click = "https://${cfg.domain}";
          default-alert = {
            enable = true;
            failure-threshold = 8;
            success-threshold = 4;
            send-on-resolved = true;
          };
          overrides = lib.singleton {
            group = config.networking.hostName;
            topic = "splitleaf";
            url = "https://ntfy.sh";
            default-alert = {
              failure-threshold = 4;
              success-threshold = 2;
            };
          };
        };
        ui.default-sort-by = "group";
        maintenance = {
          start = "03:00";
          duration = "1h";
          timezone = "Europe/Berlin";
        };

        endpoints =
          let
            mkEndpoint = endpoint: {
              inherit (endpoint) name group interval;
              url = "${endpoint.protocol}://${endpoint.domain}${endpoint.path}";
              alerts = lib.mkIf endpoint.enableAlerts [ { type = "ntfy"; } ];
              ssh = lib.mkIf (endpoint.protocol == "ssh") {
                username = "";
                password = "";
              };
              conditions = lib.concatLists [
                endpoint.extraConditions
                (lib.optional (lib.elem endpoint.protocol [
                  "http"
                  "https"
                ]) "[STATUS] == 200")
                (lib.optional (lib.elem endpoint.protocol [
                  "tcp"
                  "ssh"
                  "icmp"
                ]) "[CONNECTED] == true")
              ];
            };
          in
          cfg.endpoints |> lib.attrValues |> lib.filter (endpoint: endpoint.enable) |> lib.map mkEndpoint;
      };
    };

    systemd.services.gatus.environment.GATUS_DELAY_START_SECONDS = "5";

    custom = {
      web-services.gatus.endpoints =
        let
          defaultEndpoints =
            self.allHosts
            |> lib.mapAttrs (
              _: host:
              host.config.custom.services.caddy.virtualHosts |> lib.attrValues |> lib.map (vHost: vHost.domain)
            )
            |> lib.concatMapAttrs (
              hostName: domains:
              domains
              |> lib.filter (domain: domain != cfg.domain)
              |> lib.map (
                domain:
                lib.nameValuePair domain {
                  inherit domain;
                  group = hostName;
                }
              )
              |> lib.listToAttrs
            );
        in
        lib.mkIf cfg.generateDefaultEndpoints (
          defaultEndpoints
          // {
            "healthchecks.io" = {
              group = "external";
              domain = "hc-ping.com";
              path = "/\${HEALTHCHECKS_PING_KEY}/${config.networking.hostName}-gatus-uptime?create=1";
              interval = "2h";
            };
          }
        );

      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [ dataDir ];
    };
  };
}
