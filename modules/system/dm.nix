{
    config,
    pkgs,
    lib,
    ...
}: let
    cfg = config.myConfig.dm;
in {
    options.myConfig.dm = {
        lightdm.enable = lib.mkEnableOption "";
        gdm.enable = lib.mkEnableOption "";
        sddm.enable = lib.mkEnableOption "";
    };

    config = {
        services.xserver = {
            enable = true;

            displayManager = {
                lightdm = lib.mkIf cfg.lightdm.enable {
                    enable = true;
                    greeters.slick.enable = true;
                };

                gdm.enable = cfg.gdm.enable;

                sddm = lib.mkIf cfg.sddm.enable {
                    enable = true;
                    theme = "chili";
                };
            };
        };

        environment.systemPackages = lib.mkIf cfg.sddm.enable [pkgs.sddm-chili-theme];

        myConfig.x-input.enable = true;
    };
}
