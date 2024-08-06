{ config, lib, ... }:
{
  options.myConfig.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.git.enable {
    sops.secrets.github-ssh-key.path = "${config.home.homeDirectory}/.ssh/github";

    programs = {
      git = {
        enable = true;
        userName = "SebastianStork";
        userEmail = "sebastian.stork@pm.me";
        extraConfig.init.defaultBranch = "main";
      };

      lazygit.enable = true;

      ssh = {
        enable = true;
        matchBlocks."github.com".identityFile = "~/.ssh/github";
      };
    };
  };
}
