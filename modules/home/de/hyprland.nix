{
    inputs,
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
    imports = [
        inputs.hyprlock.homeManagerModules.hyprlock
        inputs.hypridle.homeManagerModules.hypridle
    ];

    options.myConfig.de.hyprland.enable = lib.mkEnableOption "";

    config = lib.mkIf cfg.hyprland.enable {
        home.packages = [pkgs.hyprpaper];
        xdg.configFile."hypr/hyprpaper.conf".text = ''
            preload=${cfg.wallpaper}
            wallpaper=,${cfg.wallpaper}
            splash=false
        '';

        programs.hyprlock = {
            enable = true;
            backgrounds = [
                {
                    path = "screenshot";
                    blur_passes = 1;
                    blur_size = 6;
                }
            ];
        };

        services.hypridle = let
            hyprlockExe = "${lib.getExe inputs.hyprlock.packages.${pkgs.system}.default}";
        in {
            enable = true;
            lockCmd = "pidof ${hyprlockExe} || ${hyprlockExe}";
            # beforeSleepCmd = "loginctl lock-session";
            afterSleepCmd = "hyprctl dispatch dpms on";
            listeners = [
                {
                    timeout = 300;
                    onTimeout = "hyprctl dispatch dpms off";
                    onResume = "hyprctl dispatch dpms on";
                }
                {
                    timeout = 600;
                    onTimeout = "loginctl lock-session";
                }
                {
                    timeout = 1200;
                    onTimeout = "systemctl suspend";
                }
            ];
        };

        myConfig.rofi.enable = true;
        services.cliphist.enable = true;

        wayland.windowManager.hyprland = {
            enable = true;

            settings = {
                "$mod" = "SUPER";
                "$terminal" = "kitty";
                "$menu" = "rofi -show drun";
                "$browser" = "brave";
                "$fileManager" = "nemo";
                "$editor" = "codium";

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
                        "$mod, R, exec, $menu"
                        "$mod, V, exec, ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"
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

                        # Resize window
                        "$mod CONTROL, left, resizeactive, -100 0"
                        "$mod CONTROL, right, resizeactive, 100 0"
                        "$mod CONTROL, up, resizeactive, 0 -100"
                        "$mod CONTROL, down, resizeactive, 0 100"

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
                # Move/resize windows
                bindm = [
                    "$mod, mouse:272, movewindow"
                    "$mod, mouse:273, resizewindow"
                ];
            };
        };
    };
}
