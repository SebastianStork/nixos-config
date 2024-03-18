{
    config,
    pkgs,
    lib,
    ...
}: {
    options.myConfig.doas.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.doas.enable {
        security.sudo.enable = false;

        environment.systemPackages = [pkgs.git];

        security.doas = {
            enable = true;
            extraRules = [
                {
                    groups = ["wheel"];
                    keepEnv = true;
                    persist = true;
                }
            ];
        };

        environment.shellAliases.sudo = "doas";
        programs.bash.interactiveShellInit = "complete -F _command doas";
    };
}
