{
    config,
    lib,
    ...
}: let
    cfg = config.myConfig.shell;
in {
    options.myConfig.shell = {
        bash.enable = lib.mkEnableOption "";
        zsh.enable = lib.mkEnableOption "";
        starship.enable = lib.mkEnableOption "";
        nixAliases.enable = lib.mkEnableOption "";
        improvedCommands.enable = lib.mkEnableOption "";
        direnv.enable = lib.mkEnableOption "";
    };

    config = lib.mkMerge [
        {
            programs.bash.enable = cfg.bash.enable;

            programs.zsh.enable = cfg.zsh.enable;

            programs.starship = lib.mkIf cfg.starship.enable {
                enable = true;
                enableBashIntegration = cfg.bash.enable;
                enableZshIntegration = cfg.zsh.enable;
                settings = {
                    cmd_duration.disabled = true;
                    directory = {
                        truncation_length = 0;
                        truncation_symbol = "…/";
                        truncate_to_repo = false;
                    };
                };
            };

            programs.direnv = lib.mkIf cfg.direnv.enable {
                enable = true;
                nix-direnv.enable = true;
                config.global.hide_env_diff = true;
            };
        }

        (lib.mkIf cfg.nixAliases.enable {
            home.shellAliases = {
                nr = "sudo nixos-rebuild --flake $FLAKE";
                nrs = "nr switch";
                nrt = "nr test";
                nrb = "nr boot";
                nrrb = "nrb && reboot";
                nu = "sudo nix flake update";
            };
        })

        (lib.mkIf cfg.improvedCommands.enable {
            programs.lsd = {
                enable = true;
                enableAliases = true;
            };

            programs.bat.enable = true;
            home.shellAliases.cat = "bat -p";

            programs.fzf.enable = true;

            programs.zoxide = {
                enable = true;
                options = ["--cmd cd"];
            };
        })
    ];
}
