{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.services.cliphist.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.cliphist.enable {
    assertions = [
      {
        assertion = config.custom.programs.rofi.enable;
        message = "cliphist requires rofi";
      }
    ];

    services.cliphist = {
      enable = true;
      allowImages = false;
    };

    systemd.user.services.cliphist.Service.ExecStopPost =
      "${lib.getExe config.services.cliphist.package} wipe";

    home.packages = [
      pkgs.wl-clipboard
      (pkgs.writeScriptBin "rofi-clipboard" "cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy")
    ];
  };
}
