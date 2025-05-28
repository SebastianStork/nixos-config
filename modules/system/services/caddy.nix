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

  allVirtualHosts =
    config.custom.services.caddy.virtualHosts |> lib.filterAttrs (_: value: value.enable);

  isTailscaleDomain = domain: domain |> lib.hasSuffix config.custom.services.tailscale.domain;

  tailscaleHostsExist = lib.any (v: isTailscaleDomain v.domain) (lib.attrValues allVirtualHosts);
  nonTailscaleHostsExist = lib.any (v: !isTailscaleDomain v.domain) (lib.attrValues allVirtualHosts);

  getSubdomain = domain: domain |> lib.splitString "." |> lib.head;
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

  config = lib.mkIf (allVirtualHosts != { }) (
    lib.mkMerge [
      {
        services.caddy = {
          enable = true;
          virtualHosts = lib.mapAttrs' (
            _: v:
            lib.nameValuePair v.domain {
              extraConfig = lib.concatStrings [
                (lib.optionalString (isTailscaleDomain v.domain) ''
                  bind tailscale/${getSubdomain v.domain}
                  tailscale_auth
                '')
                "reverse_proxy localhost:${toString v.port}"
              ];
            }
          ) allVirtualHosts;
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
