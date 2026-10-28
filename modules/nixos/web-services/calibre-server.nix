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
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain} = {
        inherit (cfg) port;
        forwardAuth = {
          enable = cfg.forwardAuth;
          bypassPaths = [
            "/opds*"
            "/get/*"
          ];
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
