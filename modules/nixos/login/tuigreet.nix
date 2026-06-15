{
  config,
  self,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.login.tuigreet;
in
{
  options.custom.login.tuigreet = {
    enable = lib.mkEnableOption "";
    autoLogin = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      useTextGreeter = true;
      settings = {
        default_session.command =
          let
            sessionData = config.services.displayManager.sessionData.desktops;
          in
          self.lib.concatWords [
            (lib.getExe pkgs.tuigreet)
            "--time"
            "--asterisks"
            "--remember"
            "--remember-user-session"
            "--sessions '${sessionData}/share/wayland-sessions:${sessionData}/share/xsessions'"
          ];
        initial_session = lib.mkIf (cfg.autoLogin && config.custom.desktop.hyprland.enable) {
          command = lib.getExe' pkgs.hyprland "start-hyprland";
          user = "seb";
        };
      };
    };
  };
}
