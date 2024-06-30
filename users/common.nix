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
    ../modules/home-manager
    ../wrappers

    {
      programs.home-manager.enable = true;
      systemd.user.startServices = "sd-switch";

      xdg = {
        enable = true;
        userDirs = {
          enable = true;
          createDirectories = true;
          extraConfig.XDG_SCREENSHOTS_DIR = "$HOME/Pictures/Screenshots";
        };
      };
    }
  ];
}
