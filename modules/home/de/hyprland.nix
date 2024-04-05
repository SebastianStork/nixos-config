{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.de;
in {
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

                decoration.drop_shadow = false;
                animations.enabled = false;

                bind =
                    [
                        # Essentials
                        "$mod CONTROL, Q, exit,"
                        "$mod SHIFT, C, killactive,"
                        "$mod, TAB, cyclenext,"
                        "$mod SHIFT, V, togglefloating,"
                        "$mod SHIFT, F, fullscreen, 0"

                        # Launch programs
                        "$mod, RETURN, exec, $terminal"
                        "$mod, R, exec, $menu"
                        "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
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
