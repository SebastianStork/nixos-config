{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.dm.tuigreet;
in
{
  options.custom.dm.tuigreet = {
    enable = lib.mkEnableOption "";
    autoLogin = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session.command =
          let
            sessionData = config.services.displayManager.sessionData.desktops;
          in
          lib.concatStringsSep " " [
            (lib.getExe pkgs.greetd.tuigreet)
            "--time"
            "--asterisks"
            "--remember"
            "--remember-user-session"
            "--sessions '${sessionData}/share/wayland-sessions:${sessionData}/share/xsessions'"
          ];
        initial_session = lib.mkIf cfg.autoLogin {
          command = lib.getExe pkgs.hyprland;
          user = "seb";
        };
      };
    };

    # Prevent systemd messages from covering the TUI
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInputs = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };
}
