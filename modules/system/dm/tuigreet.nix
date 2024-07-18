{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.myConfig.dm.tuigreet.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.dm.tuigreet.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session =
          let
            sessionData = config.services.displayManager.sessionData.desktops;
          in
          {
            user = "greeter";
            command = lib.concatStringsSep " " [
              (lib.getExe pkgs.greetd.tuigreet)
              "--time"
              "--asterisks"
              "--remember"
              "--remember-user-session"
              "--sessions '${sessionData}/share/wayland-sessions:${sessionData}/share/xsessions'"
            ];
          };
      };
    };
  };
}
