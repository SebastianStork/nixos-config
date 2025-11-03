{
  config,
  pkgs,
  lib,
  lib',
  ...
}:
let
  cfg = config.custom.services.caddy;
  inherit (config.services.caddy) user;

  virtualHosts = cfg.virtualHosts |> lib.attrValues |> lib.filter (value: value.enable);

  publicHostsExist = virtualHosts |> lib.any (value: !lib'.isTailscaleDomain value.domain);
  tailscaleHostsExist = virtualHosts |> lib.any (value: lib'.isTailscaleDomain value.domain);

  webPorts = [
    80
    443
  ];

  mkVirtualHost =
    { domain, port, ... }:
    lib.nameValuePair domain {
      logFormat = "output file ${config.services.caddy.logDir}/${domain}.log { mode 640 }";
      extraConfig = ''
        ${lib.optionalString (lib'.isTailscaleDomain domain) "bind tailscale/${lib'.subdomainOf domain}"}
        reverse_proxy localhost:${toString port}
      '';
    };
in
{
  options.custom.services.caddy = {
    enable = lib.mkEnableOption "" // {
      default = virtualHosts != { };
    };
    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 49514;
    };
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "" // {
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
  };

  config = lib.mkIf (virtualHosts != [ ]) (
    lib.mkMerge [
      {
        meta.ports.tcp.list = [ cfg.metricsPort ];

        services.caddy = {
          enable = true;
          enableReload = false;
          globalConfig = ''
            admin off
            metrics { per_host }
          '';
          extraConfig = ":49514 { metrics /metrics }";
          virtualHosts = virtualHosts |> lib.map mkVirtualHost |> lib.listToAttrs;
        };

        custom.persist.directories = [ "/var/lib/caddy" ];
      }

      (lib.mkIf publicHostsExist {
        meta.ports.tcp.list = webPorts;
        networking.firewall.allowedTCPPorts = webPorts;
      })

      (lib.mkIf tailscaleHostsExist {
        sops.secrets."tailscale/service-auth-key" = {
          owner = user;
          restartUnits = [ "caddy.service" ];
        };

        services.caddy = {
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/tailscale/caddy-tailscale@v0.0.0-20250508175905-642f61fea3cc" ];
            hash = "sha256-o9/ueYS1yD8H4j9uKu/wDGw02r8gEPzI80Hxs70tsL8=";
          };
          globalConfig = ''
            tailscale {
              auth_key {file.${config.sops.secrets."tailscale/service-auth-key".path}}
              ephemeral true
            }
          '';
        };
      })
    ]
  );
}
