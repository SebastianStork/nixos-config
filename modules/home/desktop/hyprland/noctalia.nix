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
        noctalia-shell.enable = true;
      };

      services.cliphist.enable = true;
    };

    home.packages = [ pkgs.grimblast ];

    wayland.windowManager.hyprland.extraConfig = lib.mkBefore ''
      # Variables
      $ipc = noctalia-shell ipc call
      $play-pause = $ipc media playPause
      $play-next = $ipc media next
      $play-previous = $ipc media previous
      $mute = $ipc volume muteOutput
      $volume-up = $ipc volume increase
      $volume-down = $ipc volume decrease
      $mute-mic = $ipc volume muteInput

      # Launch programs
      bind = SUPER, R, exec, $ipc launcher toggle
      bind = SUPER, V, exec, $ipc launcher clipboard

      # Manage session
      bindrl = SUPER CONTROL, L, exec, $ipc lockScreen lock
      bindrl = SUPER CONTROL, S, exec, $ipc sessionMenu lockAndSuspend
    '';
  };
}
