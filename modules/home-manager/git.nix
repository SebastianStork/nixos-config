{ config, lib, ... }:
{
  options.myConfig.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.git.enable {
    programs.git = {
      enable = true;
      userName = "SebastianStork";
      userEmail = "sebastian.stork@pm.me";
      extraConfig.init.defaultBranch = "main";
    };
    programs.lazygit.enable = true;

    sops.secrets.github-ssh-key.path = "${config.home.homeDirectory}/.ssh/github";
    programs.ssh = {
      enable = true;
      matchBlocks."github.com".identityFile = "~/.ssh/github";
    };
  };
}
