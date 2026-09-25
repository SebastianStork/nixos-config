{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.blocking-nameserver;
  netCfg = config.custom.networking;

  recursiveNameservers =
    allHosts
    |> lib.attrValues
    |> lib.filter (host: host.config.custom.services.recursive-nameserver.enable)
    |> lib.map (
      host:
      "${host.config.custom.networking.overlay.address}:${lib.toString host.config.custom.services.recursive-nameserver.port}"
    );
in
{
  options.custom.services.blocking-nameserver = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 53;
    };
    gui = {
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 58479;
      };
      forwardAuth = lib.mkEnableOption "";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = self.lib.isPrivateDomain cfg.gui.domain;
      message = self.lib.mkUnprotectedMessage "AdGuard Home";
    };

    services = {
      adguardhome = {
        enable = true;
        mutableSettings = false;

        host = "127.0.0.1";
        inherit (cfg.gui) port;

        settings = {
          dns = {
            bind_hosts = [
              netCfg.overlay.address
            ]
            ++ lib.optional netCfg.underlay.trusted netCfg.underlay.address;
            inherit (cfg) port;

            upstream_dns =
              if (recursiveNameservers != [ ]) then recursiveNameservers else [ "9.9.9.9#dns.quad9.net" ];
            upstream_mode = "parallel";
            hostsfile_enabled = false;
            bootstrap_dns = [
              "1.1.1.1"
              "8.8.8.8"
            ];
          };

          clients.persistent =
            lib.optional (netCfg.underlay.trusted && config.custom.services.recursive-nameserver.enable)
              {
                name = "LAN";
                ids = [ netCfg.underlay.cidr ];
                upstreams = [
                  "[/${config.networking.domain}/]127.0.0.1:${lib.toString config.custom.services.recursive-nameserver.port}"
                ]
                ++ recursiveNameservers;
              };

          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
          };
          filters =
            [
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_48.txt"
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt"
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt"
            ]
            |> lib.map (url: {
              enabled = true;
              inherit url;
            });
        };
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        inherit (cfg) port;
        proto = "any";
        group = "client";
      };
    };

    networking.firewall.interfaces.${netCfg.underlay.interface} = lib.mkIf netCfg.underlay.trusted {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };

    systemd.services.adguardhome = {
      enableStrictShellChecks = false;
      requires = [ netCfg.overlay.systemdUnit ];
      after = [ netCfg.overlay.systemdUnit ];
    };

    custom = {
      services.caddy.virtualHosts.${cfg.gui.domain} = lib.mkIf (cfg.gui.domain != null) {
        port = cfg.gui.port;
        forwardAuth = {
          enable = cfg.gui.forwardAuth;
          bypassPaths = [
            "/control/stats"
            "/control/status"
          ];
        };
      };

      persistence.directories = [ "/var/lib/private/AdGuardHome" ];

      meta.sites.${cfg.gui.domain} = lib.mkIf (cfg.gui.domain != null) {
        title = "Adguard Home";
        icon = "sh:adguard-home";
        checkPath = "/control/status";
      };
    };
  };
}
