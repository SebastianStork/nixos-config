{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.steam.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.steam.enable {
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
