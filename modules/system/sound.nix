{
    config,
    lib,
    ...
}: {
    options.myConfig.sound.pipewire.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.sound.pipewire.enable {
        security.rtkit.enable = true;
        hardware.pulseaudio.enable = false;
        services.pipewire = {
            enable = true;
            wireplumber.enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
        };
    };
}
