{ self, ... }:
{
  imports = [ self.homeManagerModules.default ];

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
