{
    config,
    lib,
    osConfig,
    ...
}: {
    options.myConfig.spotifyd.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.spotifyd.enable {
        sops.secrets = {
            "spotify/username" = {};
            "spotify/password" = {};
        };

        services.spotifyd = {
            enable = true;

            settings.global = {
                username_cmd = "cat ${config.sops.secrets."spotify/username".path}";
                password_cmd = "cat ${config.sops.secrets."spotify/password".path}";
                device_name = "${osConfig.networking.hostName}";
                initial_volume = "40";
                volume_normalisation = true;
            };
        };
    };
}
