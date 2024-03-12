{
  config,
  lib,
  ...
}: {
  options.myConfig.doas.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.doas.enable {
    security.sudo.enable = false;

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
    programs.bash.interactiveShellInit = lib.mkIf config.myConfig.shell.bash.enable "complete -F _command doas";
  };
}
