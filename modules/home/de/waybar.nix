{
  config,
  lib,
  wrappers,
  ...
}:
{
  options.myConfig.de.waybar.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.waybar.enable {
    programs.waybar = {
      enable = true;
      package = wrappers.waybar;
      systemd.enable = true;
    };

    systemd.user.services.waybar.Unit.After = [ "sound.target" ];
  };
}
