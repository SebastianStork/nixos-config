{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.actualbudget;

  inherit (config.services.actual.settings) dataDir;
in
{
  options.custom.web-services.actualbudget = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5006;
    };
    doBackups = lib.mkEnableOption "";
    privateAuthDomain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default =
        allHosts
        |> lib.attrValues
        |> lib.map (host: (self.lib.uncheckedHostConfig host).custom.services.private-auth)
        |> lib.filter (privateAuth: privateAuth.enable)
        |> lib.map (privateAuth: privateAuth.domain)
        |> self.lib.exactlyOne "enabled private auth instance";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."actualbudget/oidc-client-secret" = {
      owner = config.users.users.actual.name;
      restartUnits = [ "actual.service" ];
    };

    users = {
      users.actual = {
        isSystemUser = true;
        group = config.users.groups.actual.name;
      };
      groups.actual = { };
    };

    systemd.services.actual.serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateTmp = true;
      RemoveIPC = true;
    };

    services.actual = {
      enable = true;
      settings = {
        hostname = "localhost";
        inherit (cfg) port;
        enforceOpenId = true;
        openId = {
          discoveryURL = "https://${cfg.privateAuthDomain}";
          client_id = "actualbudget";
          client_secret._secret = config.sops.secrets."actualbudget/oidc-client-secret".path;
          server_hostname = "https://${cfg.domain}";
        };
      };
    };

    custom = {
      services = {
        private-auth.oidcClients.actualbudget = {
          clientName = "Actual Budget";
          redirectUris = [ "https://${cfg.domain}/openid/callback" ];
        };

        caddy.virtualHosts.${cfg.domain}.port = cfg.port;

        restic.backups.actual = lib.mkIf cfg.doBackups {
          conflictingService = "actual.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = [ dataDir ];

      meta.sites.${cfg.domain} = {
        title = "Actual Budget";
        icon = "actual-budget";
      };
    };
  };
}
