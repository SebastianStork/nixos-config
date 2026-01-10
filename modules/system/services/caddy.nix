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

  publicHostsExist =
    virtualHosts
    |> lib.any (value: (!lib'.isPrivateDomain value.domain) && (!lib'.isTailscaleDomain value.domain));
  tailscaleHostsExist = virtualHosts |> lib.any (value: lib'.isTailscaleDomain value.domain);
  privateHostsExist = virtualHosts |> lib.any (value: lib'.isPrivateDomain value.domain);

  webPorts = [
    80
    443
  ];

  mkVirtualHost =
    {
      domain,
      port,
      files,
      ...
    }:
    lib.nameValuePair domain {
      logFormat = "output file ${config.services.caddy.logDir}/${domain}.log { mode 640 }";
      extraConfig = lib.concatLines [
        (lib.optionalString (lib'.isTailscaleDomain domain) "bind tailscale/${lib'.subdomainOf domain}")
        (lib.optionalString (lib'.isPrivateDomain domain) (
          let
            certDir = config.security.acme.certs.${domain}.directory;
          in
          ''
            tls ${certDir}/fullchain.pem ${certDir}/key.pem
            bind ${config.custom.services.nebula.node.address}
          ''
        ))
        (lib.optionalString (port != null) "reverse_proxy localhost:${toString port}")
        (lib.optionalString (files != null) ''
          root * ${files}
          encode
          file_server
        '')
      ];
    };
in
{
  options.custom.services.caddy = {
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
                type = lib.types.nullOr lib.types.port;
                default = null;
              };
              files = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
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
        assertions = lib.singleton {
          assertion = virtualHosts |> lib.all ({ port, files, ... }: lib.xor (port != null) (files != null));
          message = "Each caddy virtual host must set exactly one of `port` or `files`";
        };

        meta.ports.tcp = [ cfg.metricsPort ];

        services.caddy = {
          enable = true;
          enableReload = false;
          globalConfig = ''
            admin off
            metrics { per_host }
          '';
          extraConfig = ":${toString cfg.metricsPort} { metrics /metrics }";
          virtualHosts = virtualHosts |> lib.map mkVirtualHost |> lib.listToAttrs;
        };

        custom.persistence.directories = [ "/var/lib/caddy" ];
      }

      (lib.mkIf publicHostsExist {
        meta.ports.tcp = webPorts;
        networking.firewall.allowedTCPPorts = webPorts;
      })

      (lib.mkIf tailscaleHostsExist {
        sops.secrets."tailscale/service-auth-key" = {
          owner = user;
          restartUnits = [ "caddy.service" ];
        };

        services.caddy = {
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/tailscale/caddy-tailscale@v0.0.0-20251117033914-662ef34c64b1" ];
            hash = "sha256-3lc2oSLFIco5Pgz1QNH2hT5tDTPZ4wcbc+NKH9wLEfY=";
          };
          globalConfig = ''
            tailscale {
              auth_key {file.${config.sops.secrets."tailscale/service-auth-key".path}}
              ephemeral true
            }
          '';
        };
      })

      (lib.mkIf privateHostsExist {
        sops.secrets = {
          "porkbun/api-key".owner = config.users.users.acme.name;
          "porkbun/secret-api-key".owner = config.users.users.acme.name;
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = "acme@sstork.dev";
            dnsProvider = "porkbun";
            dnsResolver = "1.1.1.1:53";
            group = config.users.users.caddy.name;
            credentialFiles = {
              PORKBUN_API_KEY_FILE = config.sops.secrets."porkbun/api-key".path;
              PORKBUN_SECRET_API_KEY_FILE = config.sops.secrets."porkbun/secret-api-key".path;
            };
            reloadServices = [ "caddy.service" ];
          };

          certs =
            virtualHosts
            |> lib.filter (host: lib'.isPrivateDomain host.domain)
            |> lib.map (host: lib.nameValuePair host.domain { })
            |> lib.listToAttrs;
        };

        services.nebula.networks.mesh.firewall.inbound = [
          {
            port = "80";
            proto = "tcp";
            host = "any";
          }
          {
            port = "443";
            proto = "tcp";
            host = "any";
          }
        ];

        systemd.services.caddy = {
          requires = [ "nebula@mesh.service" ];
          after = [ "nebula@mesh.service" ];
        };
      })
    ]
  );
}
