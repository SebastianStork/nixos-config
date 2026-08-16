{ config, lib, ... }:
let
  colors =
    {
      dark = {
        alpha = 0.85;
        background = "000000";
        foreground = "dddddd";
        cursor = "111111 cccccc";
        selection-foreground = "000000";
        selection-background = "fffacd";
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
      light = {
        alpha = 0.85;
        background = "ffffff";
        foreground = "24292f";
        cursor = "111111 0969da";
        selection-foreground = "ffffff";
        selection-background = "0969da";
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
    }
    .${config.custom.theme};
in
{
  options.custom.programs.foot.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.foot.enable {
    programs.foot = {
      enable = true;
      server.enable = true;
      settings = {
        main = {
          font = "JetBrainsMono Nerd Font:style=Medium:size=11";
          initial-color-theme = config.custom.theme;
        };
        tweak.box-drawing-base-thickness = 0.08;
        bell.system = "no";
        scrollback.lines = 10000;
        cursor.style = "beam";
        "colors-${config.custom.theme}" = colors;
      };
    };
  };
}
