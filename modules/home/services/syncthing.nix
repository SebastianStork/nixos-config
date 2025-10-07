{ config, lib, ... }@moduleArgs:
{
  options.custom.services.syncthing.enable = lib.mkEnableOption "" // {
    default = moduleArgs.osConfig.custom.services.syncthing.enable or false;
  };

  config = lib.mkIf config.custom.services.syncthing.enable {
    home.file."Projects/.stignore".text = ''
      (?d)target/
      (?d).direnv/
      (?d)result
    '';
  };
}
