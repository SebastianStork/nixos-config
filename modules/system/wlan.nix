{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.wlan.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.wlan.enable {
    sops.secrets = {
      "iwd/WLAN-233151" = { };
      "iwd/Fairphone4" = { };
      "iwd/LGS" = { };
    };

    networking.wireless.iwd = {
      enable = true;

      settings = {
        General.EnableNetworkConfiguration = true;
        Settings.AutoConnect = true;
        Network.NameResolvingService = "resolvconf";
      };
    };

    systemd.tmpfiles.rules = [
      "C /var/lib/iwd/WLAN-233151.psk 0600 root root - ${config.sops.secrets."iwd/WLAN-233151".path}"
      "C /var/lib/iwd/Fairphone4.psk 0600 root root - ${config.sops.secrets."iwd/Fairphone4".path}"
      "C /var/lib/iwd/LGS.8021x 0600 root root - ${config.sops.secrets."iwd/LGS".path}"
    ];

    environment.systemPackages = [ pkgs.iwgtk ];
  };
}
