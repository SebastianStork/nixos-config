{
  config,
  osConfig,
  lib,
  ...
}:
{
  options.custom.services.syncthing.enable = lib.mkEnableOption "" // {
    default = osConfig.custom.services.syncthing.enable;
  };

  config = lib.mkIf config.custom.services.syncthing.enable {
    home.file."Projects/.stignore".text = ''
      (?d)target/
      (?d).direnv/
      (?d)result
    '';
  };
}
