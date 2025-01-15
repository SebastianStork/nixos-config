{
  config,
  pkgs,
  lib,
  wrappers,
  ...
}:
{
  options.myConfig.de.cliphist.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.de.cliphist.enable {
    services.cliphist = {
      enable = true;
      allowImages = false;
    };

    systemd.user.services.cliphist.Service.ExecStopPost =
      "${lib.getExe config.services.cliphist.package} wipe";

    home.packages = [
      (wrappers.rofi { inherit (config.myConfig.de) theme; })
      pkgs.wl-clipboard
      (pkgs.writeScriptBin "rofi-clipboard" "cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy")
    ];
  };
}
