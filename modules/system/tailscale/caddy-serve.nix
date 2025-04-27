{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  nodes = config.myConfig.tailscale.caddyServe |> lib.filterAttrs (_: value: value.enable);

  caddy-tailscale = pkgs-unstable.caddy.withPlugins {
    plugins = [ "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556" ];
    hash = "sha256-USKNTAvxmuxzhqA8e8XERr1U8513ONG54Md5vcDUERg=";
  };
in
{
  options.myConfig.tailscale.caddyServe = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            enable = lib.mkEnableOption "" // {
              default = true;
            };
            subdomain = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = name;
            };
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
            };
          };
        }
      )
    );
    default = { };
  };

  config = lib.mkIf (nodes != { }) {
    sops.secrets."service-tailscale-auth-key" = {
      owner = config.services.caddy.user;
      inherit (config.services.caddy) group;
    };

    services.caddy = {
      enable = true;
      package = caddy-tailscale;
      enableReload = false;

      globalConfig = ''
        tailscale {
          auth_key {file.${config.sops.secrets."service-tailscale-auth-key".path}}
        }
      '';

      virtualHosts = lib.mapAttrs' (
        _: value:
        lib.nameValuePair "https://${value.subdomain}.${config.networking.domain}" {
          extraConfig = ''
            bind tailscale/${value.subdomain}
            tailscale_auth
            reverse_proxy localhost:${toString value.port}
          '';
        }
      ) nodes;
    };
  };
}
