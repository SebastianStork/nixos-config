{
  config,
  pkgs,
  lib,
  ...
}:
let
  caddyWithTailscale = pkgs.caddy.withPlugins {
    plugins = [ "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556" ];
    hash = "sha256-wt3+xCsT83RpPySbL7dKVwgqjKw06qzrP2Em+SxEPto=";
  };

  virtualHosts =
    config.custom.services.caddy.virtualHosts |> lib.filterAttrs (_: value: value.enable);

  isTailscaleDomain = domain: domain |> lib.hasSuffix config.custom.services.tailscale.domain;

  tailscaleHostsExist = lib.any (v: isTailscaleDomain v.domain) (lib.attrValues virtualHosts);
  nonTailscaleHostsExist = lib.any (v: !isTailscaleDomain v.domain) (lib.attrValues virtualHosts);

  getSubdomain = domain: domain |> lib.splitString "." |> lib.head;

  mkVirtualHostConfig = domain: port: {
    logFormat = "output file ${config.services.caddy.logDir}/access-${domain}.log { mode 640 }";
    extraConfig = ''
      ${lib.optionalString (isTailscaleDomain domain) ''
        bind tailscale/${getSubdomain domain}
        tailscale_auth
      ''}
      reverse_proxy localhost:${toString port}
    '';
  };
in
{
  options.custom.services.caddy.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            domain = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = name;
            };
            port = lib.mkOption {
              type = lib.types.port;
              default = null;
            };
          };
        }
      )
    );
    default = { };
  };

  config = lib.mkIf (virtualHosts != { }) (
    lib.mkMerge [
      {
        services.caddy = {
          enable = true;
          virtualHosts =
            virtualHosts
            |> lib.mapAttrs' (
              _: value: lib.nameValuePair value.domain (mkVirtualHostConfig value.domain value.port)
            );
        };

        networking.firewall.allowedTCPPorts = lib.mkIf nonTailscaleHostsExist [
          80
          443
        ];
      }

      (lib.mkIf tailscaleHostsExist {
        sops.secrets."service-tailscale-auth-key".owner = config.services.caddy.user;

        services.caddy = {
          package = caddyWithTailscale;
          enableReload = false;
          globalConfig = ''
            tailscale {
              auth_key {file.${config.sops.secrets."service-tailscale-auth-key".path}}
            }
          '';
        };
      })
    ]
  );
}
