{...}: {
    imports = [./default.nix];

    home-manager.users.seb = {
        myConfig.de.widget = {
            backlight = {
                enable = true;
                device = "amdgpu_bl1";
            };
            battery.enable = true;
        };

        wayland.windowManager.hyprland.settings.monitor = "eDP-1,1920x1080@60,0x0,1";

        services.hypridle = {
            beforeSleepCmd = "loginctl lock-session";
            listeners = [
                {
                    timeout = 300;
                    onTimeout = "brillo -q -O && brillo -q -S 10";
                    onResume = "brillo -q -I";
                }
                {
                    timeout = 1200;
                    onTimeout = "systemctl suspend";
                }
            ];
        };
    };
}
