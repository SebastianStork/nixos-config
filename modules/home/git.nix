{ config, lib, ... }:
{
  options.myConfig.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.git.enable {
    sops.secrets = {
      "github-ssh-key".path = "${config.home.homeDirectory}/.ssh/github";
      "hda-gitlab-ssh-key".path = "${config.home.homeDirectory}/.ssh/hda-gitlab";
    };

    programs = {
      git = {
        enable = true;

        userName = "SebastianStork";
        userEmail = "sebastian.stork@pm.me";
        extraConfig.init.defaultBranch = "main";

        includes = [
          {
            condition = "gitdir:~/Projects/h-da/**";
            contents = {
              user = {
                name = "Sebastian Stork";
                email = "sebastian.stork@stud.h-da.de";
              };
              init.defaultBranch = "main";
            };
          }
        ];
      };

      ssh = {
        enable = true;
        matchBlocks = {
          "github.com".identityFile = "~/.ssh/github";
          "code.fbi.h-da.de".identityFile = "~/.ssh/hda-gitlab";
        };
      };

      lazygit.enable = true;
    };
  };
}
