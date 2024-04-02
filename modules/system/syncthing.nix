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
                    seb-laptop.id = "GUXHL6J-J2HWYNN-7JZJ5CN-6LPYGJD-H7GYRLQ-ORZ4PJJ-5K4WT7I-MELMIQO";
                };

                folders = let
                    allDevices = ["seb-desktop" "seb-laptop"];
                    staggeredVersioning = {
                        type = "staggered";
                        params = {
                            cleanInterval = "3600"; # 1 hour in seconds
                            maxAge = "15552000"; # 180 days in seconds
                        };
                    };
                in {
                    Documents = {
                        path = "/home/seb/Documents";
                        devices = allDevices;
                        versioning = staggeredVersioning;
                        ignorePerms = false;
                    };
                    Downloads = {
                        path = "/home/seb/Downloads";
                        devices = allDevices;
                        versioning = staggeredVersioning;
                        ignorePerms = false;
                    };
                    Pictures = {
                        path = "/home/seb/Pictures";
                        devices = allDevices;
                        versioning = staggeredVersioning;
                        ignorePerms = false;
                    };
                    Music = {
                        path = "/home/seb/Music";
                        devices = allDevices;
                        versioning = staggeredVersioning;
                        ignorePerms = false;
                    };
                    Videos = {
                        path = "/home/seb/Videos";
                        devices = allDevices;
                        versioning = staggeredVersioning;
                        ignorePerms = false;
                    };
                    Projects = {
                        path = "/home/seb/Projects";
                        devices = allDevices;
                        ignorePerms = false;
                    };
                };
            };
        };
    };
}
