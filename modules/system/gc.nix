{ config, lib, ... }:
{
  options.myConfig.gc.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.gc.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 10 --keep-since 7d";
      };
    };
  };
}
