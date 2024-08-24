{
  config,
  pkgs,
  lib,
  ...
}:
let
  pskSsids = [
    "WLAN-233151"
    "Fairphone4"
    "DSL_EXT"
  ];
in
{
  options.myConfig.wlan.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.wlan.enable (
    lib.mkMerge [
      {
        networking.wireless.iwd = {
          enable = true;
          settings = {
            General.EnableNetworkConfiguration = true;
            Settings.AutoConnect = true;
            Network.NameResolvingService = "resolvconf";
          };
        };

        environment.systemPackages = [ pkgs.iwgtk ];
      }

      (lib.mkMerge (
        lib.forEach pskSsids (ssid: {
          sops = {
            secrets."wlan/${ssid}/key" = { };

            templates."iwd/${ssid}.psk".content = ''
              [Security]
              Passphrase=${config.sops.placeholder."wlan/${ssid}/key"}
            '';
          };

          systemd.tmpfiles.rules = [
            "C /var/lib/iwd/${ssid}.psk - - - - ${config.sops.templates."iwd/${ssid}.psk".path}"
          ];
        })
      ))
    ]
  );
}
