{ config, lib, ... }:
{
  options.myConfig.nix-helper.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.nix-helper.enable {
    environment.sessionVariables.FLAKE = "/home/seb/Projects/nixos/my-config";
    programs.nh.enable = true;
  };
}
