{ config, lib, ... }:
let
  cfg = config.myConfig.nix-helper;
in
{
  options.myConfig.nix-helper = {
    enable = lib.mkEnableOption "";
    auto-gc.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    programs.nh.enable = true;

    programs.nh.clean = lib.mkIf cfg.auto-gc.enable {
      enable = true;
      dates = "daily";
      extraArgs = "--keep 10 --keep-since 3d";
    };
  };
}
