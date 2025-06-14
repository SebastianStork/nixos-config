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
  };

  config = lib.mkIf cfg.enable {
    meta.ports.list = [ cfg.port ];

    services.gatus = {
      enable = true;

      settings = {
        web.port = cfg.port;

        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
        };

        connectivity.checker.target = "1.1.1.1:53";

        alerting = {
          ntfy = {
            topic = "uptime";
            url = "https://alerts.${tailscaleDomain}";
            click = "https://${cfg.domain}";
            default-alert = {
              enable = true;
              failure-threshold = 4;
              success-threshold = 2;
              send-on-resolved = true;
            };
          };
        };

        maintenance = {
          start = "03:00";
          duration = "1h";
          timezone = "Europe/Berlin";
        };

        endpoints =
          let
            mkHttpCheck =
              {
                name,
                group,
                url,
                conditions ? [ ],
              }:
              {
                inherit name group url;
                conditions = [ "[STATUS] == 200" ] ++ conditions;
                interval = "30s";
                alerts = [ { type = "ntfy"; } ];
              };
          in
          [
            {
              name = "Syncthing";
              group = "Private";
              url = "tcp://alto.${tailscaleDomain}:22000";
              conditions = [ "[CONNECTED] == true" ];
              interval = "30s";
              alerts = [ { type = "ntfy"; } ];
            }
            (mkHttpCheck {
              name = "Syncthing GUI";
              group = "Private";
              url = "https://syncthing.${tailscaleDomain}/rest/noauth/health";
              conditions = [ "[BODY].status == OK" ];
            })
            (mkHttpCheck {
              name = "Nextcloud";
              group = "Private";
              url = "https://cloud.${tailscaleDomain}/status.php";
              conditions = [
                "[BODY].installed == true"
                "[BODY].maintenance == false"
                "[BODY].needsDbUpgrade == false"
              ];
            })
            (mkHttpCheck {
              name = "Actual Budget";
              group = "Private";
              url = "https://budget.${tailscaleDomain}/";
            })
            (mkHttpCheck {
              name = "Hedgedoc";
              group = "Public";
              url = "https://docs.sprouted.cloud/_health";
              conditions = [ "[BODY].ready == true" ];
            })
            (mkHttpCheck {
              name = "Forgejo";
              group = "Public";
              url = "https://git.sstork.dev/api/healthz";
              conditions = [ "[BODY].status == pass" ];
            })
            {
              name = "Forgejo SSH";
              group = "Public";
              url = "ssh://git.sstork.dev";
              ssh = {
                username = "";
                password = "";
              };
              conditions = [ "[CONNECTED] == true" ];
              interval = "30s";
              alerts = [ { type = "ntfy"; } ];
            }
            (mkHttpCheck {
              name = "Ntfy";
              group = "Monitoring";
              url = "https://alerts.${tailscaleDomain}/v1/health";
              conditions = [ "[BODY].healthy == true" ];
            })
          ];
      };
    };
  };
}
