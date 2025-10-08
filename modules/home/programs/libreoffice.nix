{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.libreoffice.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.libreoffice.enable {
    home.packages = [
      pkgs.libreoffice
      pkgs.hunspell
      pkgs.hunspellDicts.de_DE
      pkgs.hunspellDicts.en_US
    ];
  };
}
