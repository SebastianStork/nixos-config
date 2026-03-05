{ config, lib, ... }:
{
  config = lib.mkIf config.custom.programs.hyprland.enable {
    wayland.windowManager.hyprland.extraConfig = ''
      # Bindflags:
      # r = release
      # e = repeat
      # l = locked

      # Essentials
      bind = SUPER SHIFT, C, killactive,
      bind = SUPER SHIFT, V, togglefloating,
      bind = SUPER SHIFT, F, fullscreen, 0

      # Launch programs
      bind = SUPER, RETURN, exec, kitty
      bind = SUPER, B, exec, firefox
      bind = SUPER, C, exec, code

      # Move focus
      bind = SUPER, left, movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up, movefocus, u
      bind = SUPER, down, movefocus, d
      bind = SUPER, TAB, cyclenext,

      # Move window
      bind = SUPER SHIFT, left, movewindow, l
      bind = SUPER SHIFT, right, movewindow, r
      bind = SUPER SHIFT, up, movewindow, u
      bind = SUPER SHIFT, down, movewindow, d
      bindm = SUPER, mouse:272, movewindow

      # Resize window
      binde = SUPER CONTROL, left, resizeactive, -100 0
      binde = SUPER CONTROL, right, resizeactive, 100 0
      binde = SUPER CONTROL, up, resizeactive, 0 -100
      binde = SUPER CONTROL, down, resizeactive, 0 100
      bindm = SUPER, mouse:273, resizewindow

      # Switch workspace
      ${lib.concatMapStringsSep "\n" (n: ''
        bind = SUPER, ${toString n}, focusworkspaceoncurrentmonitor, ${toString n}
        bind = SUPER SHIFT, ${toString n}, movetoworkspacesilent, ${toString n}
      '') (lib.range 1 9)}

      # Manage session
      bindrl = SUPER CONTROL, Q, exit,
      bindrl = SUPER CONTROL, P, exec, poweroff
      bindrl = SUPER CONTROL, R, exec, reboot
      bindrl = SUPER CONTROL, H, exec, systemctl hibernate
      bindrl = SUPER CONTROL, B, exec, sleep 1 && hyprctl dispatch dpms off

      # Control media
      bindl = , XF86AudioPlay, exec, $play-pause
      bindel = SHIFT, XF86AudioRaiseVolume, exec, $play-next
      bindel = SHIFT, XF86AudioLowerVolume, exec, $play-previous
      bindl = , XF86AudioMute, exec, $mute
      bindel = , XF86AudioRaiseVolume, exec, $volume-up
      bindel = , XF86AudioLowerVolume, exec, $volume-down
      bindl = SHIFT, XF86AudioMute, exec, $mute-mic

      bindl = SUPER ALT, RETURN, exec, $play-pause
      bindel = SUPER ALT, right, exec, $play-next
      bindel = SUPER ALT, left, exec, $play-previous
      bindl = SUPER ALT, BACKSPACE, exec, $mute
      bindel = SUPER ALT, up, exec, $volume-up
      bindel = SUPER ALT, down, exec, $volume-down
      bindl = SUPER ALT, M, exec, $mute-mic

      ${lib.optionalString config.custom.programs.brightnessctl.enable ''
        # Adjust brightness
        bindel = , XF86MonBrightnessUp, exec, brightnessctl --exponent set +2%
        bindel = , XF86MonBrightnessDown, exec, brightnessctl --exponent set 2%-
      ''}

      # Screenshot
      bind = , Print, exec, grimblast --notify --freeze copysave output
      bind = SHIFT, Print, exec, grimblast --notify --freeze copysave area
      bind = CONTROL, Print, exec, grimblast --notify --freeze copysave active

      # Special workspaces
      bind = SUPER, Q, togglespecialworkspace, flake
      bind = SUPER, S, togglespecialworkspace, music
      bind = SUPER, D, togglespecialworkspace, chat
      bind = SUPER, M, togglespecialworkspace, monitor
      bind = SUPER, F, togglespecialworkspace, files
      bind = SUPER, N, togglespecialworkspace, notes
    '';
  };
}
