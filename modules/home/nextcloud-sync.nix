{
  config,
  pkgs,
  lib,
  ...
}:
let
  paths = [
    "Documents"
    "Downloads"
    "Pictures"
    "Music"
    "Videos"
    "Projects"
  ];
  syncCommand =
    path:
    "nextcloudcmd ${
      lib.concatStringsSep " " [
        "--user seb"
        "--password \"$(cat ${config.sops.secrets."nextcloud-password".path})\""
        "--path /Sync/${path}"
        "--non-interactive"
        "~/${path}"
        "https://cloud.stork-atlas.ts.net"
      ]
    }";
in
{
  options.myConfig.nextcloud-sync.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.nextcloud-sync.enable {
    sops.secrets."nextcloud-password" = { };

    systemd.user = {
      services.nextcloud-autosync = {
        Service = {
          ExecStart = lib.getExe' (pkgs.writeShellApplication {
            name = "nextcloud-sync-script";
            runtimeInputs = [ pkgs.nextcloud-client ];
            text = builtins.concatStringsSep "\n" (map syncCommand paths);
          }) "nextcloud-sync-script";
        };
      };

      timers.nextcloud-autosync = {
        Install.WantedBy = [ "default.target" ];
        Timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "5min";
        };
        Unit.After = [ "network-online.target" ];
      };
    };
  };
}
