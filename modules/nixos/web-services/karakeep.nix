{ config, lib, ... }:
let
  cfg = config.custom.web-services.karakeep;
in
{
  options.custom.web-services.karakeep = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 18195;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets."karakeep/openai-api-key" = { };
      templates."karakeep.env" = {
        content = "OPENAI_API_KEY=${config.sops.placeholder."karakeep/openai-api-key"}";
        owner = config.users.users.karakeep.name;
        restartUnits = [ "karakeep-web.service" ];
      };
    };

    services.karakeep = {
      enable = true;
      environmentFile = config.sops.templates."karakeep.env".path;
      extraEnvironment = {
        PORT = toString cfg.port;
        DISABLE_NEW_RELEASE_CHECK = "true";
        OCR_LANGS = "eng,deu";
      };
    };

    users = {
      users.meilisearch = {
        isSystemUser = true;
        group = config.users.groups.meilisearch.name;
      };
      groups.meilisearch = { };
    };

    systemd.services.meilisearch.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = config.users.users.meilisearch.name;
      Group = config.users.groups.meilisearch.name;
      ReadWritePaths = lib.mkForce [ ];
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      persistence.directories = [
        "/var/lib/karakeep"
        "/var/lib/meilisearch"
      ];
    };
  };
}
