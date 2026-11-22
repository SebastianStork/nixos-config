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
    manager = lib.mkOption {
      type = lib.types.enum [
        "networkd"
        "networkmanager"
      ];
      default = "networkd";
    };
    interface = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    useDhcp = lib.mkEnableOption "";
    isPublic = lib.mkEnableOption "";
    isRoaming = lib.mkEnableOption "";
    cidr = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
    address = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = if cfg.cidr != null then cfg.cidr |> lib.splitString "/" |> lib.head else null;
      readOnly = true;
    };
    trusted = lib.mkEnableOption "";
    gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
    };
    wireless = {
      enable = lib.mkEnableOption "";
      networks = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default = config.custom.sops.secretsData.iwd |> lib.attrNames;
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = lib.singleton {
        assertion =
          cfg.manager == "networkmanager" -> (cfg.useDhcp && cfg.cidr == null && cfg.gateway == null);
        message = self.lib.mkInvalidConfigMessage "NetworkManager underlay `${config.networking.hostName}`" "only DHCP configuration is currently supported";
      };
    }

    (lib.mkIf (cfg.manager == "networkd") {
      systemd.network = {
        enable = true;
        networks."10-${cfg.interface}" = {
          matchConfig.Name = cfg.interface;
          linkConfig.RequiredForOnline = "routable";
          networkConfig.DHCP = lib.mkIf cfg.useDhcp "yes";
          dhcpV4Config.UseDNS = lib.mkIf cfg.useDhcp false;
          address = lib.optional (cfg.cidr != null) cfg.cidr;
          routes = lib.optional (cfg.gateway != null) {
            Gateway = cfg.gateway;
            GatewayOnLink = true;
          };
        };
      };
    })

    (lib.mkIf (cfg.manager == "networkd" && cfg.wireless.enable) {
      networking.wireless.iwd = {
        enable = true;
        settings.Settings.AutoConnect = true;
      };
      systemd.network.networks."10-${cfg.interface}".networkConfig.IgnoreCarrierLoss = "3s";
    })

    (lib.mkIf (cfg.manager == "networkmanager") {
      systemd.network.wait-online.enable = false;

      networking = {
        wireless.enable = lib.mkIf (!cfg.wireless.enable) (lib.mkForce false);
        networkmanager = {
          enable = true;
          wifi.backend = lib.mkIf cfg.wireless.enable "iwd";
          dns = "systemd-resolved";
          plugins = [ pkgs.networkmanager-openvpn ];
          settings.connection."vpn.persistent" = true;
          unmanaged = [ "interface-name:${config.custom.networking.overlay.interface}" ];
        };
      };

      users.users.seb.extraGroups = [ config.users.groups.networkmanager.name ];
    })

    (lib.mkIf cfg.wireless.enable {
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
