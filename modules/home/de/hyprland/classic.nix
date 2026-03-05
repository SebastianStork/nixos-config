{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.de.hyprland.classic.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.de.hyprland.classic.enable {
    custom = {
      programs = {
        hyprland.enable = true;
        rofi.enable = true;
        hyprlock.enable = true;
      };

      services = {
        wpaperd.enable = true;
        hypridle.enable = true;
        waybar.enable = true;
        cliphist.enable = true;
      };
    };

    services.dunst.enable = true;

    home.packages = [
      pkgs.playerctl
      pkgs.grimblast
    ];

    wayland.windowManager.hyprland.extraConfig = lib.mkBefore ''
      # Variables
      $play-pause = playerctl --ignore-player=firefox play-pause
      $play-next = playerctl --ignore-player=firefox next
      $play-previous = playerctl --ignore-player=firefox previous
      $mute = wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      $volume-up = wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      $volume-down = wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      $mute-mic = wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # Launch programs
      bind = SUPER, R, exec, rofi -show drun
      bind = SUPER, V, exec, rofi-clipboard

      # Manage session
      bindrl = SUPER CONTROL, L, exec, loginctl lock-session
    '';
  };
}
