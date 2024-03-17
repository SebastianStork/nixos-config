{inputs, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];

    users.mutableUsers = false;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.sharedModules = [
        ../modules/home
        {
            programs.home-manager.enable = true;
            home.stateVersion = "23.11";
            systemd.user.startServices = "sd-switch";

            xdg = {
                enable = true;

                userDirs = {
                    enable = true;
                    createDirectories = true;
                };
            };
        }
    ];
}
