{
    config,
    lib,
    ...
}: let
    cfg = config.myConfig.shell;
in {
    imports = [
        ./starship.nix
        ./direnv.nix
        ./enhancedCommands.nix
        ./nixAliases.nix
    ];

    options.myConfig.shell = {
        bash.enable = lib.mkEnableOption "";
        zsh.enable = lib.mkEnableOption "";
    };

    config = {
        programs.bash.enable = cfg.bash.enable;

        programs.zsh.enable = cfg.zsh.enable;
    };
}