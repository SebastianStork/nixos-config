{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.wlan;
in
{
  options.custom.services.wlan = {
    enable = lib.mkEnableOption "";
    networks = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = config.custom.sops.secrets.iwd |> lib.attrNames;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General.EnableNetworkConfiguration = true;
        Settings.AutoConnect = true;
      };
    };

    environment.systemPackages = [ pkgs.iwgtk ];

    sops.secrets =
      cfg.networks
      |> lib.map (name: "iwd/${name}")
      |> lib.custom.genAttrs (_: {
        restartUnits = [ "iwd.service" ];
      });

    systemd.services.iwd.preStart = ''
      rm --force /var/lib/iwd/*.{psk,8021x}
      install -m 600 /run/secrets/iwd/* /var/lib/iwd
    '';
  };
}
