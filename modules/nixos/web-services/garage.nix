{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.garage;
in
{
  options.custom.web-services.garage = {
    enable = lib.mkEnableOption "";
    rootDomain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    rpcPort = lib.mkOption {
      type = lib.types.port;
      default = 3901;
    };
    api = {
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "api.${cfg.rootDomain}";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3900;
      };
    };
    web = {
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "web.${cfg.rootDomain}";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3902;
      };
    };
    admin = {
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "admin.${cfg.rootDomain}";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3903;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."garage/rpc-secret".owner = config.users.users.garage.name;

    services.garage = {
      enable = true;
      package = pkgs-unstable.garage_2;

      settings = {
        db_engine = "sqlite";
        replication_factor = 1;

        rpc_bind_addr = "127.0.0.1:${toString cfg.rpcPort}";
        rpc_secret_file = config.sops.secrets."garage/rpc-secret".path;

        s3_api = {
          api_bind_addr = "127.0.0.1:${toString cfg.api.port}";
          s3_region = "garage";
          root_domain = ".${cfg.api.domain}";
        };

        s3_web = {
          bind_addr = "127.0.0.1:${toString cfg.web.port}";
          root_domain = ".${cfg.web.domain}";
        };

        admin.api_bind_addr = "127.0.0.1:${toString cfg.admin.port}";
      };
    };

    users = {
      users.garage = {
        isSystemUser = true;
        group = config.users.groups.garage.name;
      };
      groups.garage = { };
    };

    systemd.services.garage.serviceConfig = {
      ExecStart = lib.mkForce "${lib.getExe config.services.garage.package} server --single-node";

      DynamicUser = false;
      User = config.users.users.garage.name;
      Group = config.users.groups.garage.name;
      ProtectSystem = "strict";
      PrivateTmp = true;
      RemoveIPC = true;
    };

    custom = {
      services.caddy.virtualHosts = {
        ${cfg.api.domain}.port = cfg.api.port;
        ${cfg.admin.domain}.port = cfg.admin.port;
      };

      persistence.directories = [ "/var/lib/garage" ];

      meta.sites."${cfg.admin.domain}" = {
        title = "Garage";
        icon = "sh:garage";
        path = "/health";
      };
    };
  };
}
