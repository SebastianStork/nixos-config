{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.peer-substituter;
in
{
  options.custom.services.peer-substituter = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
    };
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.harmonia.cache = {
        enable = true;
        settings.bind = "127.0.0.1:${lib.toString cfg.port}";
      };

      custom = {
        services.caddy.virtualHosts.${cfg.domain} = {
          inherit (cfg) port;
          extraAllowedGroups = [
            "server"
            "agent"
          ];
        };

        meta.sites.${cfg.domain} = {
          title = "Peer Substituter";
          icon = "nixos";
          path = "/health";
        };
      };
    })
  ];
}
