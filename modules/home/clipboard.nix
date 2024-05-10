{
    config,
    pkgs,
    lib,
    wrappers,
    ...
}: {
    options.myConfig.clipboard.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.clipboard.enable {
        services.cliphist.enable = true;

        home.packages = [
            (pkgs.writeScriptBin "clipboard" ''
                ${lib.getExe pkgs.cliphist} list | ${lib.getExe (wrappers.rofi {inherit (config.myConfig.de) theme;})} -dmenu -display-columns 2 | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}
            '')
        ];
    };
}
