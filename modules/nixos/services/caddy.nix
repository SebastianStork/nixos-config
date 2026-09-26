{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.caddy;
  netCfg = config.custom.networking;

  nebulaHosts =
    allHosts |> lib.attrValues |> lib.filter (host: host.config.custom.services.nebula.enable);

  virtualHosts = cfg.virtualHosts |> lib.attrValues;
  privateVirtualHosts = virtualHosts |> lib.filter (vHost: self.lib.isPrivateDomain vHost.domain);

  getAuthDomain =
    service:
    allHosts
    |> lib.attrValues
    |> lib.map (host: host.config.custom.services.${service})
    |> lib.filter (auth: auth.enable)
    |> lib.map (auth: auth.domain)
    |> self.lib.headOrNull;

  forwardAuthBackends = {
    private = {
      domain = getAuthDomain "private-auth";
      uri = "/api/authz/forward-auth";
    };
    university = {
      domain = getAuthDomain "university-auth";
      uri = "/api/auth/caddy";
    };
  };

  getAllowedGroups = vHost: [ "client" ] ++ vHost.extraAllowedGroups;

  hostIsAllowed =
    vHost: host:
    lib.any (group: lib.elem group (getAllowedGroups vHost)) host.config.custom.services.nebula.groups
    || lib.elem host.config.networking.hostName vHost.extraAllowedHosts;

  getAllowedAddresses =
    vHost:
    (
      nebulaHosts
      |> lib.filter (hostIsAllowed vHost)
      |> lib.map (host: host.config.custom.networking.overlay.address)
      |> lib.unique
    )
    ++ lib.optional netCfg.underlay.trusted netCfg.underlay.cidr;

  allowedNebulaGroups = privateVirtualHosts |> lib.concatMap getAllowedGroups |> lib.unique;

  allowedNebulaHosts =
    privateVirtualHosts |> lib.concatMap (vHost: vHost.extraAllowedHosts) |> lib.unique;

  mkFirewallRules =
    target:
    [
      "80"
      "443"
    ]
    |> lib.map (
      port:
      {
        inherit port;
        proto = "tcp";
      }
      // target
    );

  publicHostsExist = virtualHosts |> lib.any (vHost: (!self.lib.isPrivateDomain vHost.domain));
  privateHostsExist = privateVirtualHosts != [ ];

  privateDomains = privateVirtualHosts |> lib.map (vHost: vHost.domain) |> lib.unique;

  mkVirtualHost =
    {
      domain,
      port,
      files,
      extraConfig,
      forwardAuth,
      ...
    }@vHost:
    lib.nameValuePair domain {
      logFormat = "output file ${config.services.caddy.logDir}/${domain}.log { mode 640 }";
      extraConfig =
        let
          certDir = config.security.acme.certs.${domain}.directory;
          allowedAddresses = vHost |> getAllowedAddresses;
          accessControl = ''
            @accessDenied not remote_ip ${allowedAddresses |> self.lib.concatWords}
            respond @accessDenied 403
          '';
          forwardAuthConfig =
            let
              backend = forwardAuthBackends.${forwardAuth.backend};
              url = lib.optionalString (backend.domain != null) "https://${backend.domain}";
            in
            lib.optionalString forwardAuth.enable ''
              ${lib.optionalString (forwardAuth.bypassPaths != [ ])
                "@forwardAuthProtected not path ${forwardAuth.bypassPaths |> self.lib.concatWords}"
              }
              forward_auth ${lib.optionalString (forwardAuth.bypassPaths != [ ]) "@forwardAuthProtected "}${url} {
                uri ${backend.uri}
              }
            '';
          requestHandlers =
            [
              (lib.optional forwardAuth.enable forwardAuthConfig)
              (lib.optional (port != null) "reverse_proxy localhost:${lib.toString port}")
              (lib.optionals (files != null) [
                "root ${files}"
                "encode"
                "file_server"
              ])
              (lib.optional (extraConfig != null) extraConfig)
            ]
            |> lib.concatLists
            |> lib.concatLines;
        in
        if self.lib.isPrivateDomain domain then
          ''
            tls ${certDir}/fullchain.pem ${certDir}/key.pem
            bind ${config.custom.networking.overlay.address} ${lib.optionalString netCfg.underlay.trusted netCfg.underlay.address}
            route {
              ${accessControl}
              ${requestHandlers}
            }
          ''
        else
          requestHandlers;
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
          { name, config, ... }:
          {
            options = {
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
              extraAllowedGroups = lib.mkOption {
                type = lib.types.listOf lib.types.nonEmptyStr;
                default = [ ];
              };
              extraAllowedHosts = lib.mkOption {
                type = lib.types.listOf lib.types.nonEmptyStr;
                default = [ ];
              };
              forwardAuth = {
                enable = lib.mkEnableOption "";
                backend = lib.mkOption {
                  type = lib.types.enum [
                    "private"
                    "university"
                  ];
                  default = if self.lib.isPrivateDomain config.domain then "private" else "university";
                };
                bypassPaths = lib.mkOption {
                  type = lib.types.listOf lib.types.nonEmptyStr;
                  default = [ ];
                };
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
              message = self.lib.mkInvalidConfigMessage "Caddy virtual host `${vHost.domain}`" "`port` and `files` cannot be set at the same time";
            }
            {
              assertion = (vHost.port != null) || (vHost.files != null) || (vHost.extraConfig != null);
              message = self.lib.mkInvalidConfigMessage "Caddy virtual host `${vHost.domain}`" "one of `port`, `files` or `extraConfig` must be set";
            }
            {
              assertion =
                (!self.lib.isPrivateDomain vHost.domain)
                || (vHost |> getAllowedAddresses) != [ ]
                || netCfg.underlay.trusted;
              message = self.lib.mkInvalidConfigMessage "Caddy virtual host `${vHost.domain}`" "no hosts are allowed to access it";
            }
            {
              assertion =
                (!vHost.forwardAuth.enable) || forwardAuthBackends.${vHost.forwardAuth.backend}.domain != null;
              message = self.lib.mkInvalidConfigMessage "Caddy virtual host `${vHost.domain}`" "no `${vHost.forwardAuth.backend}` forward authentication service was found";
            }
          ]);

        networking.firewall.allowedTCPPorts = lib.mkIf publicHostsExist [
          80
          443
        ];

        services.caddy = {
          enable = true;
          globalConfig = "metrics { per_host }";
          extraConfig = ":${lib.toString cfg.metricsPort} { metrics /metrics }";
          virtualHosts = virtualHosts |> self.lib.genAttrs' mkVirtualHost;
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
          };

          certs =
            privateDomains
            |> self.lib.genAttrs' (
              domain:
              lib.nameValuePair domain {
                reloadServices = lib.mkAfter [ "caddy.service" ];
              }
            );
        };

        services.nebula.networks.mesh.firewall.inbound =
          (allowedNebulaGroups |> lib.concatMap (group: mkFirewallRules { inherit group; }))
          ++ (allowedNebulaHosts |> lib.concatMap (host: mkFirewallRules { inherit host; }));

        networking.firewall.interfaces.${netCfg.underlay.interface}.allowedTCPPorts =
          lib.mkIf netCfg.underlay.trusted
            [
              80
              443
            ];

        systemd.services.caddy = {
          requires = [ netCfg.overlay.systemdUnit ];
          wants = privateDomains |> lib.map (domain: "acme-${domain}.service");
          after = [
            netCfg.overlay.systemdUnit
          ]
          ++ (privateDomains |> lib.map (domain: "acme-${domain}.service"));
        };

        custom.persistence.directories = [ "/var/lib/acme" ];
      })
    ]
  );
}
