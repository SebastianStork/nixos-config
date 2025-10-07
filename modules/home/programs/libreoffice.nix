{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.libreoffice.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.libreoffice.enable {
    home.packages = with pkgs; [
      libreoffice
      hunspell
      hunspellDicts.de_DE
      hunspellDicts.en_US
    ];
  };
}
