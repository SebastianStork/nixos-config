{
    inputs,
    pkgs,
    lib,
    ...
}: {
    imports = [./default.nix];

    home-manager.users.seb = {
        home.packages = [
            pkgs.obs-studio
            pkgs.libsForQt5.kdenlive
            pkgs.gimp
        ];

        wayland.windowManager.hyprland.settings.monitor = "DP-2,2560x1440@144,0x0,1";

        programs.hyprlock.package = inputs.hyprlock.packages.${pkgs.system}.default.overrideAttrs {
            postPatch = ''
                substituteInPlace src/core/hyprlock.cpp \
                --replace "5000" "16"
            '';
        };

        services.hypridle.beforeSleepCmd = lib.mkForce "";

        services.easyeffects.preset = "95X";
    };
}
