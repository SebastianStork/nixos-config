{
    config,
    lib,
    ...
}: let
    cfg = config.myConfig.nix-helper;
in {
    options.myConfig.nix-helper = {
        enable = lib.mkEnableOption "";
        auto-gc.enable = lib.mkEnableOption "";
    };

    config = lib.mkIf cfg.enable {
        programs.nh.enable = true;

        environment.shellAliases = let
            rebuild = "sudo -v && nh os";
        in {
            nrs = "${rebuild} switch";
            nrt = "${rebuild} test";
            nrb = "${rebuild} boot";
            nrrb = "nrb && reboot";
        };

        programs.direnv = {
            enable = true;
            silent = true;
        };

        programs.nh.clean = lib.mkIf cfg.auto-gc.enable {
            enable = true;
            dates = "daily";
            extraArgs = "--keep 10 --keep-since 7d";
        };
    };
}
