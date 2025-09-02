{ config, lib, ... }:
let
  cfg = config.custom.services.gatus;
  tailscaleDomain = config.custom.services.tailscale.domain;
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
    domainsToMonitor = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
    };
    endpoints = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = name;
              };
              group = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = if config.domain |> lib.hasSuffix tailscaleDomain then "Private" else "Public";
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
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops = {
      secrets."healthchecks/ping-key" = { };
      templates."gatus.env".content = ''
        HEALTHCHECKS_PING_KEY=${config.sops.placeholder."healthchecks/ping-key"}
      '';
    };

    custom.services.gatus.endpoints =
      let
        getSubdomain = domain: domain |> lib.splitString "." |> lib.head;

        defaultEndpoints =
          cfg.domainsToMonitor
          |> lib.filter (domain: domain != cfg.domain)
          |> lib.map (domain: lib.nameValuePair (getSubdomain domain) { inherit domain; })
          |> lib.listToAttrs;
      in
      {
        "healthchecks.io" = {
          group = "Monitoring";
          domain = "hc-ping.com";
          path = "/\${HEALTHCHECKS_PING_KEY}/${config.networking.hostName}-gatus-uptime?create=1";
          interval = "2h";
        };
      }
      // defaultEndpoints;

    services.gatus = {
      enable = true;

      environmentFile = config.sops.templates."gatus.env".path;
      settings = {
        web = {
          address = "localhost";
          port = cfg.port;
        };
        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
        };
        connectivity.checker.target = "1.1.1.1:53"; # Cloudflare DNS
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
          overrides = [
            {
              group = "Monitoring";
              topic = "stork-atlas";
              url = "https://ntfy.sh";
              default-alert = {
                failure-threshold = 1;
                success-threshold = 1;
              };
            }
          ];
        };
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
          cfg.endpoints |> lib.attrValues |> lib.map (entry: mkEndpoint entry);
      };
    };
  };
}
