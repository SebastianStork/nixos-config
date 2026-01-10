{ config, lib, ... }:
let
  cfg = config.custom.services.gc;
in
{
  options.custom.services.gc = {
    enable = lib.mkEnableOption "";
    onlyCleanRoots = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs =
          [
            "--keep 10"
            "--keep-since 7d"
            (lib.optionalString cfg.onlyCleanRoots "--no-gc")
          ]
          |> lib.concatStringsSep " ";
      };
    };
  };
}
