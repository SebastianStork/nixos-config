{
    pkgs,
    lib,
    ...
}: {
    imports = [./default.nix];

    home-manager.users.seb = {
        myConfig.de.theme = "light";

        wayland.windowManager.hyprland.settings.monitor = "eDP-1,1920x1080@60,0x0,1";

        services.hypridle.listeners = [
            {
                timeout = 300;
                onTimeout = "${lib.getExe pkgs.brightnessctl} -s && ${lib.getExe pkgs.brightnessctl} -e set 10%";
                onResume = "${lib.getExe pkgs.brightnessctl} -r";
            }
            {
                timeout = 1200;
                onTimeout = "systemctl suspend";
            }
        ];
    };
}
