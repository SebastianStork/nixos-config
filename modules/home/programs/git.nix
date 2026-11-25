{
  config,
  lib,
  allHosts,
  ...
}:
{
  options.custom.programs.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.git.enable {
    sops.secrets."git-ssh-key".path = "${config.home.homeDirectory}/.ssh/id_ed25519_git";

    programs = {
      git = {
        enable = true;

        settings = {
          init.defaultBranch = "main";
          user = {
            name = "SebastianStork";
            email = "git@sstork.dev";
          };
        };

        signing = {
          format = "ssh";
          key = config.sops.secrets."git-ssh-key".path;
          signByDefault = true;
        };

        includes = lib.singleton {
          condition = "gitdir:~/Projects/h-da/**";
          contents.user = {
            name = "Sebastian Stork";
            email = "sebastian.stork@stud.h-da.de";
          };
        };
      };

      lazygit.enable = true;

      ssh.settings =
        let
          forgejoSshSettings =
            allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config.custom.web-services.forgejo.enable)
            |> lib.filter (host: host.config.custom.web-services.forgejo.ssh.enable)
            |> lib.map (host: {
              name = host.config.custom.web-services.forgejo.domain;
              value = {
                hostName = host.config.networking.fqdn;
                user = host.config.services.forgejo.user;
                port = host.config.custom.web-services.forgejo.ssh.port;
              };
            })
            |> lib.listToAttrs;
        in
        {
          "Match user git" = {
            identityFile = config.sops.secrets."git-ssh-key".path;
            identitiesOnly = true;
          };
        }
        // forgejoSshSettings;
    };
  };
}
