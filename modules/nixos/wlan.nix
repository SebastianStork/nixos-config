{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.wlan.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.wlan.enable {
    sops = {
      secrets = {
        "wlan/WLAN-233151/key" = { };
        "wlan/Fairphone4/key" = { };
      };

      templates =
        let
          makePskFile = name: ''
            [Security]
            Passphrase=${config.sops.placeholder."wlan/${name}/key"}
          '';
        in
        {
          "iwd/WLAN-233151.psk".content = makePskFile "WLAN-233151";
          "iwd/Fairphone4.psk".content = makePskFile "Fairphone4";
        };
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
      "C /var/lib/iwd/WLAN-233151.psk 0600 root root - ${
        config.sops.templates."iwd/WLAN-233151.psk".path
      }"
      "C /var/lib/iwd/Fairphone4.psk 0600 root root - ${config.sops.templates."iwd/Fairphone4.psk".path}"
    ];

    environment.systemPackages = [ pkgs.iwgtk ];
  };
}
