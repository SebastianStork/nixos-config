{
  config,
  self,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.networking.underlay;
in
{
  options.custom.networking.underlay = {
    interface = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    useDhcp = lib.mkEnableOption "";
    isPublic = lib.mkEnableOption "";
    cidr = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
    address = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = if cfg.cidr != null then cfg.cidr |> lib.splitString "/" |> lib.head else null;
      readOnly = true;
    };
    gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
    wireless = {
      enable = lib.mkEnableOption "";
      networks = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default = config.custom.sops.secrets.iwd |> lib.attrNames;
      };
    };
  };

  config = lib.mkMerge [
    {
      networking.useNetworkd = true;
      systemd.network = {
        enable = true;
        networks."10-${cfg.interface}" = {
          matchConfig.Name = cfg.interface;
          linkConfig.RequiredForOnline = "routable";
          networkConfig.DHCP = lib.mkIf cfg.useDhcp "yes";
          address = lib.optional (cfg.cidr != null) cfg.cidr;
          routes = lib.optional (cfg.gateway != null) {
            Gateway = cfg.gateway;
            GatewayOnLink = true;
          };
        };
      };

      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade";
        dnsovertls = "opportunistic";
      };
    }

    (lib.mkIf cfg.wireless.enable {
      environment.systemPackages = [ pkgs.iwgtk ];

      networking.wireless.iwd = {
        enable = true;
        settings.Settings.AutoConnect = true;
      };

      systemd.network.networks."10-${cfg.interface}".networkConfig.IgnoreCarrierLoss = "3s";

      sops.secrets =
        cfg.wireless.networks
        |> lib.map (name: "iwd/${name}")
        |> self.lib.genAttrs (_: {
          restartUnits = [ "iwd.service" ];
        });

      systemd.services.iwd = {
        preStart = "install -m 600 /run/secrets/iwd/* /var/lib/iwd";
        postStop = "rm --force /var/lib/iwd/*.{open,psk,8021x}";
      };
    })
  ];
}
