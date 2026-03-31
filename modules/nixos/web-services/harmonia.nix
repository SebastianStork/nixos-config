{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.harmonia;

  caches =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.networking.hostName != config.networking.hostName)
    |> lib.map (host: host.config.custom.web-services.harmonia)
    |> lib.filter (cache: cache.enable);
in
{
  options.custom.web-services.harmonia = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
    };
    publicKey = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      sops.secrets."harmonia/signing-key".owner = config.users.users.harmonia.name;

      services.harmonia = {
        enable = true;
        signKeyPaths = [ config.sops.secrets."harmonia/signing-key".path ];
        settings.bind = "127.0.0.1:${toString cfg.port}";
      };

      custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;
    })

    {
      nix.settings = {
        substituters = caches |> lib.map (cache: "https://${cache.domain}");
        trusted-public-keys = caches |> lib.map (cache: cache.publicKey);
      };
    }
  ];
}
