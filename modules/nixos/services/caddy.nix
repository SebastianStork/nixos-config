{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.caddy;
  netCfg = config.custom.networking;

  virtualHosts = cfg.virtualHosts |> lib.attrValues |> lib.filter (vHost: vHost.enable);

  publicHostsExist = virtualHosts |> lib.any (vHost: (!self.lib.isPrivateDomain vHost.domain));
  privateHostsExist = virtualHosts |> lib.any (vHost: self.lib.isPrivateDomain vHost.domain);

  mkVirtualHost =
    {
      domain,
      port,
      files,
      extraConfig,
      ...
    }:
    lib.nameValuePair domain {
      logFormat = "output file ${config.services.caddy.logDir}/${domain}.log { mode 640 }";
      extraConfig =
        let
          certDir = config.security.acme.certs.${domain}.directory;
        in
        [
          (lib.optionals (self.lib.isPrivateDomain domain) [
            "tls ${certDir}/fullchain.pem ${certDir}/key.pem"
            "bind ${config.custom.networking.overlay.address}"
          ])
          (lib.optional (port != null) "reverse_proxy localhost:${toString port}")
          (lib.optionals (files != null) [
            "root * ${files}"
            "encode"
            "file_server"
          ])
          (lib.optional (extraConfig != null) extraConfig)
        ]
        |> lib.concatLists
        |> lib.concatLines;
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
              extraConfig = lib.mkOption {
                type = lib.types.nullOr lib.types.lines;
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
        assertions =
          virtualHosts
          |> lib.concatMap (vHost: [
            {
              assertion = (vHost.port == null) || (vHost.files == null);
              message = "Caddy virtual host `${vHost.domain}` cannot set both `port` and `files`";
            }
            {
              assertion = (vHost.port != null) || (vHost.files != null) || (vHost.extraConfig != null);
              message = "Caddy virtual host `${vHost.domain}` must set at least one of `port`, `files` or `extraConfig`";
            }
          ]);

        networking.firewall.allowedTCPPorts = lib.mkIf publicHostsExist [
          80
          443
        ];

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
            |> lib.filter (host: self.lib.isPrivateDomain host.domain)
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
          requires = [ netCfg.overlay.systemdUnit ];
          after = [ netCfg.overlay.systemdUnit ];
        };

        custom.persistence.directories = [ "/var/lib/acme" ];
      })
    ]
  );
}
