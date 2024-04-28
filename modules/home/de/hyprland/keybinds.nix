{
    config,
    pkgs,
    lib,
    ...
}: {
    config = lib.mkIf config.myConfig.de.hyprland.enable {
        wayland.windowManager.hyprland.extraConfig = ''
            $mod = SUPER

            # Bindflags:
            # r = release
            # e = repeat
            # l = locked

            # Essentials
            bind = $mod SHIFT, C, killactive,
            bind = $mod, TAB, cyclenext,
            bind = $mod SHIFT, V, togglefloating,
            bind = $mod SHIFT, F, fullscreen, 0

            # Launch programs
            bind = $mod, RETURN, exec, kitty
            bindr = $mod, R, exec, pkill rofi || rofi -show drun
            bind = $mod, V, exec, ${lib.getExe pkgs.cliphist} list | rofi -dmenu | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}
            bind = $mod, B, exec, brave
            bind = $mod, F, exec, nemo
            bind = $mod, C, exec, codium
            bind = $mod, S, exec, spotify
            bind = $mod, D, exec, webcord
            bind = $mod, N, exec, notepadqq --new-window

            # Move focus
            bind = $mod, left, movefocus, l
            bind = $mod, right, movefocus, r
            bind = $mod, up, movefocus, u
            bind = $mod, down, movefocus, d

            # Move window
            bind = $mod SHIFT, left, movewindow, l
            bind = $mod SHIFT, right, movewindow, r
            bind = $mod SHIFT, up, movewindow, u
            bind = $mod SHIFT, down, movewindow, d
            bindm = $mod, mouse:272, movewindow

            # Resize window
            binde = $mod CONTROL, left, resizeactive, -100 0
            binde = $mod CONTROL, right, resizeactive, 100 0
            binde = $mod CONTROL, up, resizeactive, 0 -100
            binde = $mod CONTROL, down, resizeactive, 0 100
            bindm = $mod, mouse:273, resizewindow

            # Switch workspace
            ${lib.concatLines (builtins.concatLists (builtins.genList (
                x: [
                    "bind = $mod, ${toString (x + 1)}, workspace, ${toString (x + 1)}"
                    "bind = $mod SHIFT, ${toString (x + 1)}, movetoworkspacesilent, ${toString (x + 1)}"
                ]
            )
            9))}

            # Scroll through workspaces
            bind = $mod, mouse_down, workspace, e-1
            bind = $mod, mouse_up, workspace, e+1

            # Manage session
            bindrl = $mod CONTROL, P, exec, poweroff
            bindrl = $mod CONTROL, R, exec, reboot
            bindrl = $mod CONTROL, Q, exit,
            bindrl = $mod CONTROL, S, exec, systemctl suspend
            bindrl = $mod CONTROL, L, exec, loginctl lock-session
            bindrl = $mod CONTROL, B, exec, sleep 1 && hyprctl dispatch dpms off
            bindl = , switch:on:Lid Switch, exec, systemctl suspend

            # Control media
            ${let
                play-pause = "${lib.getExe pkgs.playerctl} --ignore-player=brave play-pause";
                play-next = "${lib.getExe pkgs.playerctl} --ignore-player=brave next";
                play-previous = "${lib.getExe pkgs.playerctl} --ignore-player=brave previous";
                mute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                volume-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
                volume-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            in ''
                bindl = , XF86AudioPlay, exec, ${play-pause}
                bindel = SHIFT, XF86AudioRaiseVolume, exec, ${play-next}
                bindel = SHIFT, XF86AudioLowerVolume, exec, ${play-previous}
                bindl = , XF86AudioMute, exec, ${mute}
                bindel = , XF86AudioRaiseVolume, exec, ${volume-up}
                bindel = , XF86AudioLowerVolume, exec, ${volume-down}

                bindl = $mod ALT, RETURN, exec, ${play-pause}
                bindel = $mod ALT, right, exec, ${play-next}
                bindel = $mod ALT, left, exec, ${play-previous}
                bindl = $mod ALT, BACKSPACE, exec, ${mute}
                bindel = $mod ALT, up, exec, ${volume-up}
                bindel = $mod ALT, down, exec, ${volume-down}
            ''}

            # Adjust brightness
            bindel = , XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} -e set +2%
            bindel = , XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} -e set 2%-

            # Screenshot
            bind = , Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave output
            bind = SHIFT, Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave area
        '';
    };
}
