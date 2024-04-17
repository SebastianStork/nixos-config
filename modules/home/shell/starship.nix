{
    config,
    lib,
    ...
}: {
    options.myConfig.shell.starship.enable = lib.mkEnableOption "";

    config.programs.starship = lib.mkIf config.myConfig.shell.starship.enable {
        enable = true;

        enableBashIntegration = true;
        enableZshIntegration = true;

        settings = {
            cmd_duration.disabled = true;
            directory = {
                truncation_length = 0;
                truncation_symbol = "…/";
                truncate_to_repo = false;
            };
        };
    };
}