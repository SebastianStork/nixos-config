{
    config,
    lib,
    ...
}: let
    cfg = config.myConfig.shell.nixAliases;
in {
    options.myConfig.shell.nixAliases = {
        enable = lib.mkEnableOption "";
        nh.enable = lib.mkEnableOption "";
    };

    config.home.shellAliases = let
        rebuild =
            if cfg.nh.enable
            then "nh os"
            else "nixos-rebuild --flake $FLAKE --use-remote-sudo";
    in
        lib.mkIf cfg.enable {
            nr = "sudo -v && ${rebuild}";
            nrs = "nr switch";
            nrt = "nr test";
            nrb = "nr boot";
            nrrb = "nrb && reboot";
            nu = "nix flake update";
        };
}
