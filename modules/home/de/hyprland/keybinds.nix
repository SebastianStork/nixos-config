{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.myConfig.de.hyprland.enable {
    wayland.windowManager.hyprland.extraConfig = ''
      # Bindflags:
      # r = release
      # e = repeat
      # l = locked

      # Essentials
      bind = SUPER SHIFT, C, killactive,
      bind = SUPER SHIFT, V, togglefloating,
      bind = SUPER SHIFT, F, fullscreen, 0
      bind = SUPER, TAB, cyclenext,

      # Launch programs
      bind = SUPER, R, exec, rofi -show drun
      bind = SUPER, RETURN, exec, kitty
      bind = SUPER, V, exec, clipboard
      bind = SUPER, B, exec, brave
      bind = SUPER, F, exec, nemo
      bind = SUPER, C, exec, codium

      # Move focus
      bind = SUPER, left, movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up, movefocus, u
      bind = SUPER, down, movefocus, d

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

      # Minimize window
      bind = SUPER SHIFT, M, togglespecialworkspace, minimize
      bind = SUPER SHIFT, M, movetoworkspace, +0
      bind = SUPER SHIFT, M, togglespecialworkspace, minimize
      bind = SUPER SHIFT, M, movetoworkspace, special:minimize
      bind = SUPER SHIFT, M, togglespecialworkspace, minimize

      # Switch workspace
      ${lib.concatMapStringsSep "\n" (n: "bind = SUPER, ${toString n}, workspace, ${toString n}") (
        lib.range 1 9
      )}
      ${lib.concatMapStringsSep "\n" (
        n: "bind = SUPER SHIFT, ${toString n}, movetoworkspacesilent, ${toString n}"
      ) (lib.range 1 9)}

      # Scroll through workspaces
      bind = SUPER, mouse_down, workspace, e-1
      bind = SUPER, mouse_up, workspace, e+1

      # Manage session
      bindrl = SUPER CONTROL, Q, exit,
      bindrl = SUPER CONTROL, P, exec, poweroff
      bindrl = SUPER CONTROL, R, exec, reboot
      bindrl = SUPER CONTROL, S, exec, systemctl suspend
      bindrl = SUPER CONTROL, L, exec, loginctl lock-session
      bindrl = SUPER CONTROL, B, exec, sleep 1 && hyprctl dispatch dpms off
      bindl = , switch:on:Lid Switch, exec, systemctl suspend

      # Control media
      ${
        let
          play-pause = "${lib.getExe pkgs.playerctl} --ignore-player=brave play-pause";
          play-next = "${lib.getExe pkgs.playerctl} --ignore-player=brave next";
          play-previous = "${lib.getExe pkgs.playerctl} --ignore-player=brave previous";
          mute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          volume-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          volume-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        in
        ''
          bindl = , XF86AudioPlay, exec, ${play-pause}
          bindel = SHIFT, XF86AudioRaiseVolume, exec, ${play-next}
          bindel = SHIFT, XF86AudioLowerVolume, exec, ${play-previous}
          bindl = , XF86AudioMute, exec, ${mute}
          bindel = , XF86AudioRaiseVolume, exec, ${volume-up}
          bindel = , XF86AudioLowerVolume, exec, ${volume-down}

          bindl = SUPER ALT, RETURN, exec, ${play-pause}
          bindel = SUPER ALT, right, exec, ${play-next}
          bindel = SUPER ALT, left, exec, ${play-previous}
          bindl = SUPER ALT, BACKSPACE, exec, ${mute}
          bindel = SUPER ALT, up, exec, ${volume-up}
          bindel = SUPER ALT, down, exec, ${volume-down}
        ''
      }

      # Adjust brightness
      bindel = , XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} -e set +2%
      bindel = , XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} -e set 2%-

      # Screenshot
      bind = , Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave output
      bind = SHIFT, Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave area

      # Escape special workspace
      ${lib.concatMapStringsSep "\n" (n: "bind = SUPER, ${toString n}, togglespecialworkspace, blank") (
        lib.range 1 9
      )}
      ${lib.concatMapStringsSep "\n" (n: "bind = SUPER, ${toString n}, togglespecialworkspace, blank") (
        lib.range 1 9
      )}

      # Scratchpad workspace
      workspace = special:scratchpad, gapsout:30
      bind = SUPER , X, togglespecialworkspace, scratchpad

      # Music workspace
      workspace = special:music, border:false, gapsout:30, on-created-empty:spotify
      exec-once = [workspace special:music silent] spotify
      bind = SUPER, S, togglespecialworkspace, music

      # Chat workspace
      workspace = special:chat, border:false, gapsout:30, on-created-empty:webcord
      exec-once = [workspace special:chat silent] webcord
      bind = SUPER, D, togglespecialworkspace, chat

      # Flake workspace
      workspace = special:flake, border:false, gapsout:30, on-created-empty:kitty --directory $FLAKE --override background_opacity=0.7
      windowrulev2 = noblur, class:(kitty), onworkspace:special:flake
      bind = SUPER, Q, togglespecialworkspace, flake
    '';
  };
}
