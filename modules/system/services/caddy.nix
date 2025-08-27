{
  config,
  pkgs,
  lib,
  ...
}:
let
  caddyWithTailscale = pkgs.caddy.withPlugins {
    plugins = [ "github.com/tailscale/caddy-tailscale@v0.0.0-20250508175905-642f61fea3cc" ];
    hash = "sha256-0GsjeeJnfLsJywWzWwJcCDk5wjTSBwzqMBY7iHjPQa8=";
  };

  virtualHosts =
    config.custom.services.caddy.virtualHosts |> lib.filterAttrs (_: value: value.enable);

  isTailscaleDomain = domain: domain |> lib.hasSuffix config.custom.services.tailscale.domain;

  tailscaleHostsExist =
    virtualHosts |> lib.attrValues |> lib.any (value: isTailscaleDomain value.domain);
  nonTailscaleHostsExist =
    virtualHosts |> lib.attrValues |> lib.any (value: !isTailscaleDomain value.domain);

  getSubdomain = domain: domain |> lib.splitString "." |> lib.head;

  mkVirtualHostConfig =
    {
      domain,
      port,
      extraReverseProxyConfig,
      ...
    }:
    {
      logFormat = "output file ${config.services.caddy.logDir}/access-${domain}.log { mode 640 }";
      extraConfig = ''
        ${lib.optionalString (isTailscaleDomain domain) "bind tailscale/${getSubdomain domain}"}
        reverse_proxy localhost:${builtins.toString port} ${
          lib.optionalString (extraReverseProxyConfig != "") "{ ${extraReverseProxyConfig} }"
        }
      '';
    };

  ports = [
    80
    443
  ];
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
            tls = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            extraReverseProxyConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
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
        meta.ports.list = lib.mkIf nonTailscaleHostsExist ports;

        networking.firewall.allowedTCPPorts = lib.mkIf nonTailscaleHostsExist ports;

        services.caddy = {
          enable = true;
          enableReload = false;
          globalConfig = "admin off";
          virtualHosts =
            virtualHosts
            |> lib.mapAttrs' (
              _: value:
              lib.nameValuePair (lib.optionalString (!value.tls) "http://" + value.domain) (
                mkVirtualHostConfig value
              )
            );
        };
      }

      (lib.mkIf tailscaleHostsExist {
        sops.secrets."tailscale/service-auth-key".owner = config.services.caddy.user;

        services.caddy = {
          package = caddyWithTailscale;
          globalConfig = ''
            tailscale {
              auth_key {file.${config.sops.secrets."tailscale/service-auth-key".path}}
            }
          '';
        };
      })
    ]
  );
}
