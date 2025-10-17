{
  config,
  self,
  pkgs-unstable,
  lib,
  lib',
  ...
}:
let
  cfg = config.custom.services.gatus;
  dataDir = "/var/lib/gatus";
in
{
  options.custom.services.gatus = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
    generateDefaultEndpoints = lib.mkEnableOption "";
    endpoints = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
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
    warnings = lib.optional (lib.versionAtLeast lib.version "25.11") "TODO: Use gatus package from stable nixpkgs";

    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

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

    custom.services.gatus.endpoints =
      let
        defaultEndpoints =
          self.nixosConfigurations
          |> lib.mapAttrs (_: value: value.config.meta.domains.list)
          |> lib.concatMapAttrs (
            hostName: domains:
            domains
            |> lib.filter (domain: domain != cfg.domain)
            |> lib.map (
              domain:
              lib.nameValuePair (lib'.subdomainOf domain) {
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

    services.gatus = {
      enable = true;
      package = pkgs-unstable.gatus; # Unstable for the new UI
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
          url = "https://alerts.${config.custom.services.tailscale.domain}";
          click = "https://${cfg.domain}";
          default-alert = {
            enable = true;
            failure-threshold = 8;
            success-threshold = 4;
            send-on-resolved = true;
          };
          overrides = [
            {
              group = "Monitoring";
              topic = "stork-atlas";
              url = "https://ntfy.sh";
              default-alert = {
                failure-threshold = 4;
                success-threshold = 2;
              };
            }
          ];
        };
        ui.default-sort-by = "group";
        maintenance = {
          start = "03:00";
          duration = "1h";
          timezone = "Europe/Berlin";
        };

        endpoints =
          let
            mkEndpoint = value: {
              inherit (value) name group interval;
              url = "${value.protocol}://${value.domain}${value.path}";
              alerts = lib.mkIf value.enableAlerts [ { type = "ntfy"; } ];
              ssh = lib.mkIf (value.protocol == "ssh") {
                username = "";
                password = "";
              };
              conditions = lib.concatLists [
                value.extraConditions
                (lib.optional (lib.elem value.protocol [
                  "http"
                  "https"
                ]) "[STATUS] == 200")
                (lib.optional (lib.elem value.protocol [
                  "tcp"
                  "ssh"
                  "icmp"
                ]) "[CONNECTED] == true")
              ];
            };
          in
          cfg.endpoints |> lib.attrValues |> lib.map mkEndpoint;
      };
    };

    systemd.services.gatus.environment.GATUS_DELAY_START_SECONDS = "5";

    custom.persist.directories = [ dataDir ];
  };
}
