{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.desktop.hyprland.noctalia.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.desktop.hyprland.noctalia.enable {
    custom = {
      programs = {
        hyprland.enable = true;
        noctalia.enable = true;
      };

      services = {
        cliphist.enable = true;
        hypridle = {
          enable = true;
          lockCommand = "noctalia msg session lock";
        };
      };
    };

    home.packages = [ pkgs.grimblast ];

    wayland.windowManager.hyprland.extraConfig = lib.mkBefore ''
      # Variables
      $ipc = noctalia msg
      $play-pause = $ipc media toggle
      $play-next = $ipc media next
      $play-previous = $ipc media previous
      $mute = $ipc volume-mute
      $volume-up = $ipc volume-up
      $volume-down = $ipc volume-down
      $mute-mic = $ipc mic-mute

      # Launch programs
      bind = SUPER, R, exec, $ipc panel-toggle launcher
      bind = SUPER, V, exec, $ipc panel-toggle clipboard

      # Manage session
      bindrl = SUPER CONTROL, L, exec, loginctl lock-session
      bindrl = SUPER CONTROL, S, exec, systemctl sleep
    '';
  };
}
