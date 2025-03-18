{ config, lib, ... }:
{
  options.myConfig.garbageCollection.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.garbageCollection.enable {
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
