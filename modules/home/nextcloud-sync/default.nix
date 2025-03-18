{
  config,
  pkgs,
  lib,
  ...
}:
let
  paths = [
    "Downloads"
    "Projects"
    "Documents/h_da"
    "Documents/vault"
    "Pictures/Wallpapers"
    "Pictures/Screenshots"
  ];
  excludeList = pkgs.concatText "nextcloud-sync-exclude" [
    "${pkgs.nextcloud-client}/etc/Nextcloud/sync-exclude.lst"
    ./sync-exclude.lst
  ];
  syncCommand =
    path:
    "nextcloudcmd ${
      lib.concatStringsSep " " [
        "--user seb"
        "--password \"$(cat ${config.sops.secrets."nextcloud-password".path})\""
        "--path /${path}"
        "--non-interactive"
        "--exclude ${excludeList}"
        "~/${path}"
        "https://cloud.stork-atlas.ts.net"
      ]
    }";
in
{
  options.myConfig.nextcloudSync.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.nextcloudSync.enable {
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
