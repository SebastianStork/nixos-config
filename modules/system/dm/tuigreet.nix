{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.dm.tuigreet.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.dm.tuigreet.enable {
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
