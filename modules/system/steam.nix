{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.steam.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.steam.enable {
    programs = {
      steam.enable = true;

      gamemode = {
        enable = true;
        settings.custom = {
          start = "${lib.getExe pkgs.libnotify} 'GameMode started'";
          end = "${lib.getExe pkgs.libnotify} 'GameMode ended'";
        };
      };
    };

    environment.systemPackages = [ pkgs.mangohud ];
  };
}
