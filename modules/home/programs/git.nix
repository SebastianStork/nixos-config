{ config, lib, ... }:
{
  options.custom.programs.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.git.enable {
    sops.secrets = {
      "ssh-key/forgejo" = { };
      "ssh-key/github" = { };
      "ssh-key/hda-gitlab" = { };
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
          "git.sstork.dev".identityFile = config.sops.secrets."ssh-key/forgejo".path;
          "github.com".identityFile = config.sops.secrets."ssh-key/github".path;
          "code.fbi.h-da.de".identityFile = config.sops.secrets."ssh-key/hda-gitlab".path;
        };
      };

      lazygit.enable = true;
    };
  };
}
