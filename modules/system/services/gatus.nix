{ config, lib, ... }:
let
  cfg = config.custom.services.gatus;
in
{
  options.custom.services.gatus =
    let
      endpointType = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = name;
              };
              group = lib.mkOption {
                type = lib.types.nullOr lib.types.nonEmptyStr;
                default = null;
              };
              url = lib.mkOption {
                type = lib.types.nonEmptyStr;
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

      defaultDomainEndpoints =
        let
          getSubdomain = domain: domain |> lib.splitString "." |> lib.head;
        in
        cfg.domainsToMonitor
        |> lib.filter (domain: domain != cfg.domain)
        |> lib.map (domain: lib.nameValuePair (getSubdomain domain) { url = "https://${domain}"; })
        |> lib.listToAttrs;

      defaultHostEndpoints =
        cfg.hostsToMonitor
        |> lib.filter (hostName: hostName != config.networking.hostName)
        |> lib.map (
          hostName:
          lib.nameValuePair hostName {
            group = "Hosts";
            url = "icmp://${hostName}.${config.custom.services.tailscale.domain}";
            enableAlerts = false;
          }
        )
        |> lib.listToAttrs;
    in
    {
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
      hostsToMonitor = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default = [ ];
      };
      customEndpoints = lib.mkOption {
        type = endpointType;
        default = { };
      };
      finalEndpoints = lib.mkOption {
        type = endpointType;
        default = defaultDomainEndpoints // defaultHostEndpoints // cfg.customEndpoints;
        readOnly = true;
      };
    };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.list = [ cfg.port ];
    };

    sops = {
      secrets."healthchecks/ping-key" = { };
      templates."gatus.env".content = ''
        HEALTHCHECKS_PING_KEY=${config.sops.placeholder."healthchecks/ping-key"}
      '';
    };

    custom.services.gatus.customEndpoints."healthchecks.io" = {
      group = "Monitoring";
      url = "https://hc-ping.com/\${HEALTHCHECKS_PING_KEY}/${config.networking.hostName}-gatus-uptime?create=1";
      interval = "2h";
    };

    services.gatus = {
      enable = true;

      environmentFile = config.sops.templates."gatus.env".path;
      settings = {
        web.port = cfg.port;

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
            mkEndpoint =
              value:
              let
                isPrivate = value.url |> lib.hasInfix config.custom.services.tailscale.domain;
                deducedGroup = if isPrivate then "Private" else "Public";
              in
              {
                inherit (value) name url interval;
                group = if value.group != null then value.group else deducedGroup;
                alerts = lib.mkIf value.enableAlerts [ { type = "ntfy"; } ];
                ssh = lib.mkIf (lib.hasPrefix "ssh" value.url) {
                  username = "";
                  password = "";
                };
                conditions = lib.concatLists [
                  value.extraConditions
                  (lib.optional (lib.hasPrefix "http" value.url) "[STATUS] == 200")
                  (lib.optional (lib.hasPrefix "tcp" value.url) "[CONNECTED] == true")
                  (lib.optional (lib.hasPrefix "ssh" value.url) "[CONNECTED] == true")
                  (lib.optional (lib.hasPrefix "icmp" value.url) "[CONNECTED] == true")

                ];
              };
          in
          cfg.finalEndpoints |> lib.attrValues |> lib.map (entry: mkEndpoint entry);
      };
    };

    systemd.services.gatus.serviceConfig.AmbientCapabilities = "CAP_NET_RAW"; # Allow icmp/pings
  };
}
