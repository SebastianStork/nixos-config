{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./p10k
    ./aliases.nix
  ];

  options.myConfig.shell.zsh.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.shell.zsh.enable {
    programs.zsh = {
      enable = true;
      dotDir = ".config/zsh";

      autocd = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        ignoreAllDups = true;
        path = "${config.xdg.dataHome}/zsh/zsh_history";
      };

      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
      ];

      initExtra = ''
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-Z}'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls $realpath'
      '';
    };

    programs.fzf.enable = true;

    programs.zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global.hide_env_diff = true;
    };
  };
}
