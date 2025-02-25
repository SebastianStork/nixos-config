{ config, lib, ... }:
{
  options.myConfig.auto-gc.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.auto-gc.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--keep 10 --keep-since 7d";
      };
    };
  };
}
