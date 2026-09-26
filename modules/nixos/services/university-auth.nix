{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.custom.services.university-auth;
in
{
  options.custom.services.university-auth = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 1039;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = !self.lib.isPrivateDomain cfg.domain;
      message = self.lib.mkInvalidConfigMessage "University authentication service" "domain must be public";
    };

    sops.secrets."university-auth/gitlab-client-secret" = {
      owner = config.services.tinyauth.user;
      restartUnits = [ "tinyauth.service" ];
    };

    services.tinyauth = {
      enable = true;
      settings =
        let
          gitlabBaseUrl = "https://code.fbi.h-da.de/oauth";
        in
        {
          SERVER_ADDRESS = "127.0.0.1";
          SERVER_PORT = cfg.port;
          APPURL = "https://${cfg.domain}";
          LABELPROVIDER = "none";
          AUTH_SECURECOOKIE = true;
          OAUTH_AUTOREDIRECT = "gitlab";
          OAUTH_PROVIDERS_GITLAB_CLIENTID = "64fc9839a5ce4cdf8e6aa262b5f0e8ee80416e6d1e5ac1f5b29c1ca72457c4eb";
          OAUTH_PROVIDERS_GITLAB_CLIENTSECRETFILE =
            config.sops.secrets."university-auth/gitlab-client-secret".path;
          OAUTH_PROVIDERS_GITLAB_SCOPES = "openid,email";
          OAUTH_PROVIDERS_GITLAB_AUTHURL = "${gitlabBaseUrl}/authorize";
          OAUTH_PROVIDERS_GITLAB_TOKENURL = "${gitlabBaseUrl}/token";
          OAUTH_PROVIDERS_GITLAB_USERINFOURL = "${gitlabBaseUrl}/userinfo";
          OAUTH_PROVIDERS_GITLAB_NAME = "GitLab";
          OAUTH_PROVIDERS_GITLAB_CLAIMS_USERNAME = "username";
        };
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.extraConfig = ''
        @forwardAuth path /api/auth/caddy
        reverse_proxy @forwardAuth localhost:${lib.toString cfg.port} {
          header_up X-Forwarded-Host {http.request.header.X-Forwarded-Host}
        }

        reverse_proxy localhost:${lib.toString cfg.port}
      '';

      persistence.directories = [ config.services.tinyauth.dataDir ];

      meta.sites.${cfg.domain} = {
        title = "Tinyauth";
        icon = "sh:tinyauth";
      };
    };
  };
}
