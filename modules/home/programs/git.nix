{
  config,
  lib,
  allHosts,
  ...
}:
{
  options.custom.programs.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.git.enable {
    sops.secrets =
      config.custom.sops.secretsData.ssh-key
      |> lib.mapAttrs' (
        name: _: lib.nameValuePair "ssh-key/${name}" { path = "${config.home.homeDirectory}/.ssh/${name}"; }
      );

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
          key = config.sops.secrets."ssh-key/git.sstork.dev".path;
          signByDefault = true;
        };

        includes = lib.singleton {
          condition = "gitdir:~/Projects/h-da/**";
          contents = {
            user = {
              name = "Sebastian Stork";
              email = "sebastian.stork@stud.h-da.de";
              signingkey = config.sops.secrets."ssh-key/code.fbi.h-da.de".path;
            };
          };
        };
      };

      lazygit.enable = true;

      ssh.settings =
        let
          sshKeySettings =
            config.custom.sops.secretsData.ssh-key
            |> lib.mapAttrs (name: _: { identityFile = config.sops.secrets."ssh-key/${name}".path; });

          forgejoSshSettings =
            allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config.custom.web-services.forgejo.enable)
            |> lib.filter (host: host.config.custom.web-services.forgejo.ssh.enable)
            |> lib.map (host: {
              name = host.config.custom.web-services.forgejo.domain;
              value = {
                hostName = host.config.custom.networking.overlay.fqdn;
                user = host.config.services.forgejo.user;
                port = host.config.custom.web-services.forgejo.ssh.port;
                identitiesOnly = true;
              };
            })
            |> lib.listToAttrs;
        in
        lib.mkMerge [
          sshKeySettings
          forgejoSshSettings
        ];
    };
  };
}
