{
    config,
    lib,
    ...
}: {
    options.myConfig.x-input.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.x-input.enable {
        services.xserver = {
            enable = true;
            xkb = {
                layout = "de";
                variant = "nodeadkeys";
            };

            libinput = {
                enable = true;

                touchpad = {
                    accelProfile = "adaptive";
                    naturalScrolling = true;
                    disableWhileTyping = true;
                };

                mouse.accelProfile = "flat";
            };
        };
    };
}
