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
  options.custom.wlan.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.wlan.enable (
    lib.mkMerge (
      lib.flatten [
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

        (lib.forEach networks (name: {
          sops.secrets."iwd/${name}" = { };
          
          systemd.tmpfiles.rules = [
            "C /var/lib/iwd/${name} - - - - ${config.sops.secrets."iwd/${name}".path}"
          ];
        }))
      ]
    )
  );
}
