{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.calibre-server;
  dataDir = "/var/lib/calibre-server";
in
{
  options.custom.web-services.calibre-server = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
    forwardAuth = lib.mkEnableOption "";
    allowLocalWrite = lib.mkEnableOption "";
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.domain || cfg.forwardAuth;
      message = self.lib.mkUnprotectedMessage "Calibre-Server";
    };

    services.calibre-server = {
      enable = true;
      libraries = [ dataDir ];
      host = "localhost";
      inherit (cfg) port;
      extraFlags = lib.optional cfg.allowLocalWrite "--enable-local-write";
    };

    custom = {
      services = {
        caddy.virtualHosts.${cfg.domain} = {
          forwardAuth = {
            enable = cfg.forwardAuth;
            bypassPaths = [
              "/opds*"
              "/get/*"
            ];
          };
          extraConfig = ''
            ${lib.optionalString cfg.allowLocalWrite ''
              @writeMethod {
                method POST PUT PATCH DELETE
                not path /interface-data/*
              }
              respond @writeMethod 405

              @writePath path /cdb/* /conversion/* /fts/disable
              respond @writePath 405
            ''}
            reverse_proxy localhost:${lib.toString cfg.port}
          '';
        };

        restic.backups.calibre-server = lib.mkIf cfg.doBackups {
          conflictingService = "calibre-server.service";
          paths = [ dataDir ];
        };
      };

      persistence.directories = lib.singleton {
        directory = dataDir;
        user = config.services.calibre-server.user;
        group = config.services.calibre-server.group;
        mode = "0750";
      };

      meta.sites.${cfg.domain} = {
        title = "Calibre";
        icon = "calibre";
        checkPath = "/opds";
      };
    };
  };
}
