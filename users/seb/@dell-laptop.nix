{...}: {
    imports = [./default.nix];

    home-manager.users.seb.myConfig.de.widget = {
        backlight = {
            enable = true;
            device = "amdgpu_bl1";
        };
        battery.enable = true;
    };
}
