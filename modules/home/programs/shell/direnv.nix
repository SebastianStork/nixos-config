{ config, lib, ... }:
{
  options.custom.programs.shell.direnv.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.shell.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
