{ self, inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit self inputs;
    };
  };

  home-manager.sharedModules = [
    ../modules/home
    ../wrappers

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
