{
  config,
  pkgs,
  lib,
  ...
}:
let
  pskSsids = [
    "WLAN-233151"
    "EW90N"
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

        sops = {
          secrets = {
            "wlan/eduroam/password" = { };
            "wlan/eduroam/cert" = { };
          };

          templates."iwd/eduroam.8021x".content = ''
            [Security]
            EAP-Method=PEAP
            EAP-Identity=anonymous@h-da.de
            EAP-PEAP-CACert=${config.sops.placeholder."wlan/eduroam/cert"}
            EAP-PEAP-Phase2-Method=MSCHAPV2
            EAP-PEAP-Phase2-Identity=sebastian.stork@stud.h-da.de
            EAP-PEAP-Phase2-Password=${config.sops.placeholder."wlan/eduroam/password"}
          '';
        };

        systemd.tmpfiles.rules = [
          "C /var/lib/iwd/eduroam.8021x - - - - ${config.sops.templates."iwd/eduroam.8021x".path}"
        ];
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
