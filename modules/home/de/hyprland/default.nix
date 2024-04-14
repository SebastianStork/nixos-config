{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    imports = [
        ./waybar.nix
        ./hypridlelock.nix
    ];

    options.myConfig.de.hyprland.enable = lib.mkEnableOption "";

    config = lib.mkIf cfg.hyprland.enable {
        home.packages = [pkgs.hyprpaper];
        xdg.configFile."hypr/hyprpaper.conf".text = ''
            preload=${cfg.wallpaper}
            wallpaper=,${cfg.wallpaper}
            splash=false
        '';

        myConfig.rofi.enable = true;
        services.cliphist.enable = true;

        services.dunst.enable = true;

        wayland.windowManager.hyprland = {
            enable = true;

            settings = {
                exec-once = ["hyprpaper"];

                input = {
                    kb_layout = "de";
                    kb_variant = "nodeadkeys";

                    accel_profile = "flat";

                    touchpad = {
                        disable_while_typing = true;
                        natural_scroll = true;
                        middle_button_emulation = true;
                    };
                };

                general = {
                    gaps_in = 5;
                    gaps_out = 10;
                    border_size = 1;

                    layout = "master";
                };

                master = {
                    new_is_master = false;
                    no_gaps_when_only = 1;
                    mfact = "0.5";
                };

                decoration = {
                    rounding = 6;
                    drop_shadow = false;
                };

                animations.enabled = false;

                misc = {
                    disable_hyprland_logo = true;
                    disable_splash_rendering = true;
                    force_default_wallpaper = 0;
                };

                "$mod" = "SUPER";
                "$terminal" = "kitty";
                "$browser" = "brave";
                "$fileManager" = "nemo";
                "$editor" = "codium";

                bind =
                    [
                        # Essentials
                        "$mod CONTROL, Q, exit,"
                        "$mod CONTROL, S, exec, systemctl suspend"
                        "$mod CONTROL, L, exec, loginctl lock-session"
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

                # Repeat + Locked
                bindel = [
                    # Adjust volume
                    ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                    ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

                    # Adjust brightness
                    ", XF86MonBrightnessUp, exec, brillo -q -u 20000 -A 4"
                    ", XF86MonBrightnessDown, exec, brillo -q -u 20000 -U 4"
                ];

                # Mouse
                bindm = [
                    # Move/resize windows
                    "$mod, mouse:272, movewindow"
                    "$mod, mouse:273, resizewindow"
                ];
            };
        };
    };
}
