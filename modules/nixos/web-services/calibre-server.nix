{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.calibre-server;
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
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = self.lib.isPrivateDomain cfg.domain;
        message = self.lib.mkUnprotectedMessage "Calibre-Server";
      }
      {
        assertion = config.custom.services.syncthing.enable;
        message = self.lib.mkInvalidConfigMessage "Calibre-Server on ${config.networking.hostName}" "Syncthing must be enabled";
      }
    ];

    services.calibre-server = {
      enable = true;
      libraries = [ "${config.services.syncthing.dataDir}/Documents/Library" ];
      host = "localhost";
      inherit (cfg) port;
      inherit (config.services.syncthing) user group;
    };

    systemd.services.calibre-server.after = [ "syncthing.service" ];

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;

      meta.sites.${cfg.domain} = {
        title = "Calibre";
        icon = "sh:calibre";
      };
    };
  };
}
