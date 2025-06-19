{
  config,
  pkgs,
  lib,
  ...
}:
let
  networks = [
    "EW90N.psk"
    "Fairphone4.psk"
    "WLAN-233151.psk"
    "DSL_EXT.psk"
    "eduroam.8021x"
  ];
in
{
  options.custom.wifi.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.wifi.enable {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General.EnableNetworkConfiguration = true;
        Settings.AutoConnect = true;
        Network.NameResolvingService = "resolvconf";
      };
    };

    environment.systemPackages = [ pkgs.iwgtk ];

    sops.secrets =
      networks
      |> lib.map (name: {
        name = "iwd/${name}";
        value = { };
      })
      |> lib.listToAttrs;

    systemd.tmpfiles.rules =
      networks
      |> lib.map (name: "C /var/lib/iwd/${name} - - - - ${config.sops.secrets."iwd/${name}".path}");
  };
}
