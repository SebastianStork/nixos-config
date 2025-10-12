{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.caddy;
  inherit (config.services.caddy) user;

  virtualHosts = cfg.virtualHosts |> lib.attrValues |> lib.filter (value: value.enable);

  isTailscaleDomain = domain: lib.custom.isTailscaleDomain domain;

  tailscaleHosts = virtualHosts |> lib.filter (value: isTailscaleDomain value.domain);
  nonTailscaleHosts = virtualHosts |> lib.filter (value: !isTailscaleDomain value.domain);

  webPorts = [
    80
    443
  ];

  mkWildCardDomain =
    rootDomain: values:
    lib.nameValuePair "*.${rootDomain}" {
      logFormat = "";
      extraConfig =
        let
          mkSubdomain =
            { domain, port, ... }:
            ''
              import subdomain-log ${domain}
              @${lib.custom.subdomainOf domain} host ${domain}
              handle @${lib.custom.subdomainOf domain} {
                reverse_proxy localhost:${toString port}
              }
            '';
        in
        (values |> lib.map mkSubdomain |> lib.concatLines) + "handle { respond 404 }";
    };

  mkTailscaleHost =
    { domain, port, ... }:
    lib.nameValuePair domain {
      logFormat = "output file ${config.services.caddy.logDir}/${domain}.log { mode 640 }";
      extraConfig = ''
        bind tailscale/${lib.custom.subdomainOf domain}
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
              redirectFrom = lib.mkOption {
                type = lib.types.listOf lib.types.nonEmptyStr;
                default = [ ];
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
          package = pkgs.caddy.withPlugins {
            plugins = [
              "github.com/tailscale/caddy-tailscale@v0.0.0-20250508175905-642f61fea3cc"
              "github.com/caddy-dns/porkbun@v0.3.1"
            ];
            hash = "sha256-117vurf98sK/4o3JU3rBwNBUjnZZyFRJ1mq5T1S1IxY=";
          };
          enableReload = false;
          globalConfig = ''
            admin off
            metrics { per_host }
          '';
          virtualHosts.":${toString cfg.metricsPort}" = {
            logFormat = "";
            extraConfig = "metrics /metrics";
          };
        };

        custom.persist.directories = [ "/var/lib/caddy" ];
      }

      (lib.mkIf (nonTailscaleHosts != [ ]) {
        sops = {
          secrets."porkbun/api-key" = {
            owner = user;
            restartUnits = [ "caddy.service" ];
          };
          secrets."porkbun/api-secret-key" = {
            owner = user;
            restartUnits = [ "caddy.service" ];
          };
        };

        meta.ports.tcp.list = webPorts;
        networking.firewall.allowedTCPPorts = webPorts;

        services.caddy = {
          globalConfig = ''
            acme_dns porkbun {
              api_key {file.${config.sops.secrets."porkbun/api-key".path}}
              api_secret_key {file.${config.sops.secrets."porkbun/api-secret-key".path}}
            }
          '';
          extraConfig = ''
            (subdomain-log) {
              log {
                hostnames {args[0]}
                output file ${config.services.caddy.logDir}/{args[0]}.log { mode 640 }
              }
            }
          '';
          virtualHosts =
            nonTailscaleHosts
            |> lib.groupBy (value: lib.custom.rootDomainOf value.domain)
            |> lib.mapAttrs' mkWildCardDomain;
        };
      })

      (lib.mkIf (tailscaleHosts != [ ]) {
        sops.secrets."tailscale/service-auth-key" = {
          owner = user;
          restartUnits = [ "caddy.service" ];
        };

        services.caddy = {
          globalConfig = ''
            tailscale {
              auth_key {file.${config.sops.secrets."tailscale/service-auth-key".path}}
              ephemeral true
            }
          '';
          virtualHosts = tailscaleHosts |> lib.map mkTailscaleHost |> lib.listToAttrs;
        };
      })
    ]
  );
}
