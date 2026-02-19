{
  config,
  modulesPath,
  lib,
  ...
}:
{
  imports = [ "${modulesPath}/programs/btop.nix" ];

  options.custom.programs.btop.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.btop.enable {
    programs.btop = {
      enable = true;
      settings.color_theme =
        {
          dark = "Default";
          light = "adwaita";
        }
        .${config.custom.theme};
    };
  };
}
