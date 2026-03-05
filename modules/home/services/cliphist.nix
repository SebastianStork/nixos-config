{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.services.cliphist.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.cliphist.enable {
    services.cliphist = {
      enable = true;
      extraOptions = [ ];
    };

    systemd.user.services.cliphist.Service.ExecStopPost =
      "${lib.getExe config.services.cliphist.package} wipe";

    home.packages = [
      pkgs.wl-clipboard
    ]
    ++ lib.optional config.custom.programs.rofi.enable (
      pkgs.writeScriptBin "rofi-clipboard" "cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"
    );
  };
}
