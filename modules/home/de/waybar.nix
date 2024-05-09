{
    config,
    lib,
    myWrappers,
    ...
}: {
    options.myConfig.de.waybar.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.de.waybar.enable {
        programs.waybar = {
            enable = true;
            package = myWrappers.waybar;
            systemd.enable = true;
        };

        systemd.user.services.waybar.Unit.After = ["sound.target"];
    };
}
