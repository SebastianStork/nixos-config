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

  config = {
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

    home.shellAliases = let
      nixAliases = lib.mkIf cfg.nixAliases.enable {
        nrs = "sudo nixos-rebuild switch";
        nrb = "sudo nixos-rebuild boot";
        nrrb = "nrb && reboot";
        nrt = "sudo nixos-rebuild test";
        nu = "sudo nix flake update";
      };
      commandAliases = lib.mkIf cfg.improvedCommands.enable {
        ".." = "cd ..";
        cat = "bat -p";
      };
    in
      lib.mkMerge [nixAliases commandAliases];

    programs.lsd = lib.mkIf cfg.improvedCommands.enable {
      enable = true;
      enableAliases = true;
    };

    programs.bat.enable = cfg.improvedCommands.enable;

    programs.fzf.enable = cfg.improvedCommands.enable;

    programs.zoxide = lib.mkIf cfg.improvedCommands.enable {
      enable = true;
      options = ["--cmd cd"];
    };

    programs.direnv = lib.mkIf cfg.direnv.enable {
      enable = true;
      nix-direnv.enable = true;
      config.global.hide_env_diff = true;
    };
  };
}
