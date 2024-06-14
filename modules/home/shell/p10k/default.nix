{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.myConfig.shell.enable {
    programs.zsh = {
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = ./.;
          file = "p10k.zsh";
        }
      ];

      initExtraFirst = ''
        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"
      '';
    };
  };
}
