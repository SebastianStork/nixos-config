{ config, lib, ... }:
{
  options.custom.services.gc.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.gc.enable {
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
