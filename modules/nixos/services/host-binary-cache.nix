{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.host-binary-cache;
in
{
  options.custom.services.host-binary-cache = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
    };
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "cache.${config.networking.fqdn}";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.harmonia.cache = {
        enable = true;
        settings.bind = "127.0.0.1:${lib.toString cfg.port}";
      };

      custom.services.caddy.virtualHosts.${cfg.domain} = {
        inherit (cfg) port;
        allowedGroups = [ "automation" ];
      };
    })

    (lib.mkIf (lib.elem "automation" config.custom.services.nebula.groups) {
      nix.settings.substituters =
        allHosts
        |> lib.attrValues
        |> lib.map (host: host.config.custom.services.host-binary-cache)
        |> lib.filter (cache: cache.enable)
        |> lib.map (cache: "https://${cache.domain}?priority=40&trusted=true");
    })
  ];
}
