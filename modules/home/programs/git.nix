{
  config,
  modulesPath,
  lib,
  ...
}:
{
  imports = [
    "${modulesPath}/programs/git.nix"
    "${modulesPath}/programs/lazygit.nix"
    "${modulesPath}/programs/delta.nix"
    "${modulesPath}/programs/jujutsu.nix"
    "${modulesPath}/programs/diff-highlight.nix"
    "${modulesPath}/programs/diff-so-fancy.nix"
    "${modulesPath}/programs/difftastic.nix"
    "${modulesPath}/programs/patdiff.nix"
    "${modulesPath}/programs/riff.nix"
  ];

  options.custom.programs.git.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.git.enable {
    sops.secrets =
      config.custom.sops.secrets.ssh-key
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

      ssh.matchBlocks =
        config.custom.sops.secrets.ssh-key
        |> lib.mapAttrs (name: _: { identityFile = config.sops.secrets."ssh-key/${name}".path; });
    };
  };
}
