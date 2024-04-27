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
            bindl = , XF86AudioPlay, exec, ${lib.getExe pkgs.playerctl} --ignore-player=brave play-pause
            bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
            bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

            # Adjust brightness
            bindel = , XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} -e set +2%
            bindel = , XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} -e set 2%-

            # Screenshot
            bind = , Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave output
            bind = SHIFT, Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave area
        '';
    };
}
