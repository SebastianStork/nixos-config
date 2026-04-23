{
  config,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.librespeed;
in
{
  options.custom.web-services.librespeed = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8989;
    };
    frontend = {
      enable = lib.mkEnableOption "";
      domain = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      librespeed = {
        enable = true;
        useACMEHost = config.custom.networking.overlay.fqdn;
        settings = {
          bind_address = config.custom.networking.overlay.address;
          listen_port = cfg.port;
        };
        frontend = lib.mkIf cfg.frontend.enable {
          enable = true;
          contactEmail = "librespeed@sstork.dev";
          servers =
            allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config.custom.web-services.librespeed.enable)
            |> lib.map (host: {
              name = host.config.networking.hostName;
              server = "https://${host.config.custom.networking.overlay.fqdn}:${toString host.config.custom.web-services.librespeed.port}";
            })
            |> lib.mkForce;
        };
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        inherit (cfg) port;
        proto = "tcp";
        group = "client";
      };
    };

    security.acme.certs.${config.custom.networking.overlay.fqdn} = { };

    custom = lib.mkIf cfg.frontend.enable {
      services.caddy.virtualHosts.${cfg.frontend.domain}.extraConfig = ''
        route {
          root ${config.services.librespeed.settings.assets_path}
          reverse_proxy /backend/* ${config.custom.networking.overlay.address}:${toString cfg.port}
          respond /servers.json <<JSON
            ${builtins.toJSON config.services.librespeed.frontend.servers}
            JSON 200
          file_server
        }
      '';

      meta.sites.${cfg.frontend.domain} = {
        title = "LibreSpeed";
        icon = "sh:librespeed";
      };
    };
  };
}
