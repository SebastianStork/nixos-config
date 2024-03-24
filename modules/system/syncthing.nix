{
    config,
    lib,
    ...
}: {
    options.myConfig.syncthing.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.syncthing.enable {
        services.syncthing = {
            enable = true;

            user = "seb";
            group = "users";
            dataDir = "/home/seb";

            overrideDevices = true;
            overrideFolders = true;

            settings = {
                devices = {
                    seb-desktop.id = "DIPH5BN-N2XV57S-23W63KD-UZOZ3UI-RB24QRJ-VVPD4YM-ZMFZIXN-GPX4YA4";
                    dell-laptop.id = "GUXHL6J-J2HWYNN-7JZJ5CN-6LPYGJD-H7GYRLQ-ORZ4PJJ-5K4WT7I-MELMIQO";
                };

                folders = let
                    devices = ["seb-desktop" "dell-laptop"];
                    versioning = {
                        type = "staggered";
                        params = {
                            cleanInterval = "3600"; # 1 hour in seconds
                            maxAge = "15552000"; # 180 days in seconds
                        };
                    };
                    ignorePerms = false;
                in {
                    Documents = {
                        path = "/home/seb/Documents";
                        inherit devices versioning ignorePerms;
                    };
                    Downloads = {
                        path = "/home/seb/Downloads";
                        inherit devices versioning ignorePerms;
                    };
                    Pictures = {
                        path = "/home/seb/Pictures";
                        inherit devices versioning ignorePerms;
                    };
                    Music = {
                        path = "/home/seb/Music";
                        inherit devices versioning ignorePerms;
                    };
                    Videos = {
                        path = "/home/seb/Videos";
                        inherit devices versioning ignorePerms;
                    };
                };
            };
        };
    };
}
