{ config, lib, ... }:
{
  options.custom.programs.foot.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.foot.enable {
    programs.foot = {
      enable = true;
      server.enable = false;
      settings = {
        main = {
          font = "monospace:size=11";
          gamma-correct-blending = "yes";
          initial-color-theme = config.custom.theme;
        };
        bell.system = "no";
        scrollback.lines = 10000;
        cursor.style = "beam";
        tweak.surface-bit-depth = "8-bit";

        colors-dark = {
          alpha = 0.85;
          foreground = "dddddd";
          background = "000000";
          cursor = "111111 cccccc";
          regular0 = "000000";
          regular1 = "cc0403";
          regular2 = "19cb00";
          regular3 = "cecb00";
          regular4 = "0d73cc";
          regular5 = "cb1ed1";
          regular6 = "0dcdcd";
          regular7 = "dddddd";
          bright0 = "767676";
          bright1 = "f2201f";
          bright2 = "23fd00";
          bright3 = "fffd00";
          bright4 = "1a8fff";
          bright5 = "fd28ff";
          bright6 = "14ffff";
          bright7 = "ffffff";
        };
        colors-light = {
          alpha = 0.85;
          foreground = "24292f";
          background = "ffffff";
          selection-foreground = "ffffff";
          selection-background = "0969da";
          cursor = "ffffff 0969da";
          regular0 = "24292f";
          regular1 = "cf222e";
          regular2 = "116329";
          regular3 = "4d2d00";
          regular4 = "0969da";
          regular5 = "8250df";
          regular6 = "1b7c83";
          regular7 = "6e7781";
          bright0 = "57606a";
          bright1 = "a40e26";
          bright2 = "1a7f37";
          bright3 = "633c01";
          bright4 = "218bff";
          bright5 = "a475f9";
          bright6 = "3192aa";
          bright7 = "8c959f";
        };
      };
    };
  };
}
