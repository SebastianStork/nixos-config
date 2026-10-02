{
  config,
  inputs,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.binary-cache-router;
  priority = 10;

  s3BinaryCaches =
    allHosts
    |> lib.attrValues
    |> lib.map (host: host.config.custom.services.s3-binary-cache)
    |> lib.filter (cache: cache.enable)
    |> lib.map (cache: {
      url = "https://${cache.domain}";
      inherit priority;
    });

  peerSubstituters =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.networking.hostName != config.networking.hostName)
    |> lib.map (host: host.config.custom.services.peer-substituter)
    |> lib.filter (cache: cache.enable)
    |> lib.map (cache: {
      url = "https://${cache.domain}";
      inherit priority;
    });
in
{
  imports = [ inputs.ncro.nixosModules.default ];

  options.custom.services.binary-cache-router = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 1336;
    };
  };

  config = lib.mkIf cfg.enable {
    services.ncro = {
      enable = true;
      settings = {
        server.listen = "127.0.0.1:${lib.toString cfg.port}";
        upstreams =
          s3BinaryCaches
          ++ peerSubstituters
          ++ [
            {
              url = "https://nix-community.cachix.org";
              inherit priority;
              public_key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
            }
            {
              url = "https://cache.nixos.org";
              inherit priority;
              public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
            }
          ];
      };
    };

    nix.settings.substituters = lib.mkForce [
      "http://127.0.0.1:${lib.toString cfg.port}?trusted=true"
    ];

    custom.persistence.directories = [ "/var/lib/private/ncro" ];
  };
}
