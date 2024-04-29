{
    config,
    lib,
    ...
}: {
    options.myConfig.nix-helper.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.nix-helper.enable {
        programs.nh.enable = true;

        environment.shellAliases = let
            rebuild = "sudo -v && nh os";
        in {
            nrs = "${rebuild} switch";
            nrt = "${rebuild} test";
            nrb = "${rebuild} boot";
            nrrb = "nrb && reboot";
        };
    };
}
