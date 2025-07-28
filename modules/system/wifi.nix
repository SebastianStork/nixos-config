{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.wifi;
in
{
  options.custom.wifi = {
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
      |> lib.map (name: {
        name = "iwd/${name}";
        value = { };
      })
      |> lib.listToAttrs;

    systemd.tmpfiles.rules =
      cfg.networks
      |> lib.map (name: "C /var/lib/iwd/${name} - - - - ${config.sops.secrets."iwd/${name}".path}");
  };
}
