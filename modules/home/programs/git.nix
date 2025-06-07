{ config, lib, ... }:
{
  options.custom.programs.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.git.enable {
    sops.secrets = {
      "ssh-key/git.sstork.dev".path = "${config.home.homeDirectory}/.ssh/git.sstork.dev";
      "ssh-key/github.com".path = "${config.home.homeDirectory}/.ssh/github.com";
      "ssh-key/code.fbi.h-da.de".path = "${config.home.homeDirectory}/.ssh/code.fbi.h-da.de";
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
          "git.sstork.dev".identityFile = config.sops.secrets."ssh-key/git.sstork.dev".path;
          "github.com".identityFile = config.sops.secrets."ssh-key/github.com".path;
          "code.fbi.h-da.de".identityFile = config.sops.secrets."ssh-key/code.fbi.h-da.de".path;
        };
      };

      lazygit.enable = true;
    };
  };
}
