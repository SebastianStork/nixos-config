{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.gatus;
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
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              url = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "";
              };
              extraConditions = lib.mkOption {
                type = lib.types.listOf lib.types.nonEmptyStr;
                default = [ ];
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    meta.ports.list = [ cfg.port ];

    sops = {
      secrets."healthchecks-ping-key" = { };
      templates."gatus.env".content = ''
        HEALTHCHECKS_PING_KEY=${config.sops.placeholder."healthchecks-ping-key"}
      '';
    };

    services.gatus = {
      enable = true;
      environmentFile = config.sops.templates."gatus.env".path;

      settings = {
        web.port = cfg.port;

        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
          maximum-number-of-results = 1000;
          maximum-number-of-events = 100;
        };

        connectivity.checker.target = "1.1.1.1:53";

        alerting.ntfy = {
          topic = "uptime";
          url = "https://alerts.${config.custom.services.tailscale.domain}";
          click = "https://${cfg.domain}";
          default-alert = {
            enable = true;
            failure-threshold = 4;
            success-threshold = 2;
            send-on-resolved = true;
          };
        };

        maintenance = {
          start = "03:00";
          duration = "1h";
          timezone = "Europe/Berlin";
        };

        endpoints =
          let
            mkEndpoint = (
              {
                name,
                group,
                url,
                extraConditions,
              }:
              let
                isPrivate = lib.hasInfix config.custom.services.tailscale.domain url;
                deducedGroup = if isPrivate then "Private" else "Public";
              in
              {
                inherit name url;
                group = if group == null then deducedGroup else group;
                interval = "30s";
                alerts = [ { type = "ntfy"; } ];
                ssh = lib.mkIf (lib.hasPrefix "ssh" url) {
                  username = "";
                  password = "";
                };
                conditions = lib.concatLists [
                  extraConditions
                  (lib.optional (lib.hasPrefix "http" url) "[STATUS] == 200")
                  (lib.optional (lib.hasPrefix "tcp" url) "[CONNECTED] == true")
                  (lib.optional (lib.hasPrefix "ssh" url) "[CONNECTED] == true")
                ];
              }
            );
          in
          [
            {
              name = "Healthchecks.io";
              group = "Monitoring";
              url = "https://hc-ping.com/\${HEALTHCHECKS_PING_KEY}/gatus-uptime?create=1";
              interval = "2h";
              conditions = [ "[STATUS] == 200" ];
            }
          ]
          ++ (
            self.nixosConfigurations
            |> lib.mapAttrsToList (_: value: value.config.custom.services.gatus.endpoints)
            |> lib.map (entry: lib.mapAttrsToList (_: value: value) entry)
            |> lib.concatLists
            |> lib.map (entry: mkEndpoint entry)
          );
      };
    };
  };
}
