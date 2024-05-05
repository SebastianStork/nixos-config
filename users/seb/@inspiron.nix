{
    pkgs,
    lib,
    ...
}: {
    imports = [./default.nix];

    home-manager.users.seb = {
        myConfig.de.theme = "light";

        wayland.windowManager.hyprland.settings.monitor = "eDP-1,1920x1080@60,0x0,1";

        services.hypridle.settings.listener = [
            {
                timeout = 300;
                on-timeout = "${lib.getExe pkgs.brightnessctl} -s && ${lib.getExe pkgs.brightnessctl} -e set 10%";
                on-resume = "${lib.getExe pkgs.brightnessctl} -r";
            }
            {
                timeout = 1200;
                on-timeout = "systemctl suspend";
            }
        ];
    };
}
