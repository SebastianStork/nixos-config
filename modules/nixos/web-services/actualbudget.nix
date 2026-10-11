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
    oidc = {
      enable = lib.mkEnableOption "";
      domain = lib.mkOption {
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
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.domain;
      message = self.lib.mkUnprotectedMessage "Actual Budget";
    };

    sops.secrets."actualbudget/oidc-client-secret" = lib.mkIf cfg.oidc.enable {
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
        enforceOpenId = cfg.oidc.enable;
        openId = lib.mkIf cfg.oidc.enable {
          discoveryURL = "https://${cfg.oidc.domain}";
          client_id = "actualbudget";
          client_secret._secret = config.sops.secrets."actualbudget/oidc-client-secret".path;
          server_hostname = "https://${cfg.domain}";
        };
      };
    };

    custom = {
      services = {
        private-auth.oidcClients.actualbudget = lib.mkIf cfg.oidc.enable {
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
