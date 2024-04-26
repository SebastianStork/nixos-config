{
    config,
    pkgs,
    lib,
    ...
}: {
    config = lib.mkIf config.myConfig.de.hyprland.enable {
        wayland.windowManager.hyprland.settings = {
            "$mod" = "SUPER";
            "$terminal" = "kitty";
            "$browser" = "brave";
            "$fileManager" = "nemo";
            "$editor" = "codium";

            bind =
                [
                    # Essentials
                    "$mod SHIFT, C, killactive,"
                    "$mod, TAB, cyclenext,"
                    "$mod SHIFT, V, togglefloating,"
                    "$mod SHIFT, F, fullscreen, 0"

                    # Launch programs
                    "$mod, RETURN, exec, $terminal"
                    "$mod, V, exec, ${lib.getExe pkgs.cliphist} list | rofi -dmenu | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}"
                    "$mod, B, exec, $browser"
                    "$mod, F, exec, $fileManager"
                    "$mod, C, exec, $editor"
                    "$mod, S, exec, spotify"
                    "$mod, D, exec, webcord"

                    # Move focus
                    "$mod, left, movefocus, l"
                    "$mod, right, movefocus, r"
                    "$mod, up, movefocus, u"
                    "$mod, down, movefocus, d"

                    # Move window
                    "$mod SHIFT, left, movewindow, l"
                    "$mod SHIFT, right, movewindow, r"
                    "$mod SHIFT, up, movewindow, u"
                    "$mod SHIFT, down, movewindow, d"

                    # Scroll through workspaces
                    "$mod, mouse_down, workspace, e-1"
                    "$mod, mouse_up, workspace, e+1"

                    # Screenshot
                    ", Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave output"
                    "SHIFT, Print, exec, ${lib.getExe pkgs.grimblast} --notify --freeze copysave area"
                ]
                # Switch workspace
                ++ (
                    builtins.concatLists (builtins.genList (
                        x: [
                            "$mod, ${toString (x + 1)}, workspace, ${toString (x + 1)}"
                            "$mod SHIFT, ${toString (x + 1)}, movetoworkspacesilent, ${toString (x + 1)}"
                        ]
                    )
                    9)
                );

            # Release
            bindr = [
                # Launcher
                "$mod, R, exec, pkill rofi || rofi -show drun"
            ];

            # Repeat
            binde = [
                # Resize window
                "$mod CONTROL, left, resizeactive, -100 0"
                "$mod CONTROL, right, resizeactive, 100 0"
                "$mod CONTROL, up, resizeactive, 0 -100"
                "$mod CONTROL, down, resizeactive, 0 100"
            ];

            # Locked
            bindl = [
                ", switch:on:Lid Switch, exec, systemctl suspend"

                # Media
                ", XF86AudioPlay, exec, ${lib.getExe pkgs.playerctl} --player=spotify play-pause"
                ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ];

            # Release + Locked
            bindrl = [
                # Manage session
                "$mod CONTROL, P, exec, poweroff"
                "$mod CONTROL, R, exec, reboot"
                "$mod CONTROL, Q, exit,"
                "$mod CONTROL, S, exec, systemctl suspend"
                "$mod CONTROL, L, exec, loginctl lock-session"
                "$mod CONTROL, B, exec, sleep 1 && hyprctl dispatch dpms off"
            ];

            # Repeat + Locked
            bindel = [
                # Adjust volume
                ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

                # Adjust brightness
                ", XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} -e set +2%"
                ", XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} -e set 2%-"
            ];

            # Mouse
            bindm = [
                # Move/resize windows
                "$mod, mouse:272, movewindow"
                "$mod, mouse:273, resizewindow"
            ];
        };
    };
}
