{ config, lib, ... }:
let
  cfg = config.custom.services.outline;
in
{
  options.custom.services.outline = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 32886;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops.secrets."outline/gitlab-auth-secret" = {
      owner = config.users.users.outline.name;
      restartUnits = [ "outline.service" ];
    };

    services.outline = {
      enable = true;
      publicUrl = "https://${cfg.domain}";
      inherit (cfg) port;
      forceHttps = false;
      storage.storageType = "local";

      # See https://docs.getoutline.com/s/hosting/doc/rate-limiter-HSqErsUgXH
      rateLimiter = {
        enable = true;
        requests = 1000;
      };

      # See https://docs.getoutline.com/s/hosting/doc/gitlab-GjNVvyv7vW
      oidcAuthentication =
        let
          baseURL = "https://code.fbi.h-da.de/oauth";
        in
        {
          clientId = "0cb1f65501ea59bcafb3d7d7cb66235926635a3f52cf719a919c87984997002d";
          clientSecretFile = config.sops.secrets."outline/gitlab-auth-secret".path;
          authUrl = "${baseURL}/authorize";
          tokenUrl = "${baseURL}/token";
          userinfoUrl = "${baseURL}/userinfo";
          usernameClaim = "username";
          displayName = "GitLab";
          scopes = [
            "openid"
            "email"
          ];
        };
    };

    systemd.services.outline.enableStrictShellChecks = false;
  };
}
