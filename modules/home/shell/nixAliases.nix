{
    config,
    lib,
    ...
}: {
    options.myConfig.shell.nixAliases.enable = lib.mkEnableOption "";

    config.home.shellAliases = lib.mkIf config.myConfig.shell.nixAliases.enable {
        nr = "sudo -v && nixos-rebuild --flake $FLAKE --use-remote-sudo";
        nrs = "nr switch";
        nrt = "nr test";
        nrb = "nr boot";
        nrrb = "nrb && reboot";
        nu = "nix flake update";
    };
}
