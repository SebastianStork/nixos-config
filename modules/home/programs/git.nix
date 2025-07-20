{ config, lib, ... }:
{
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
        matchBlocks =
          config.custom.sops.secrets.ssh-key
          |> lib.mapAttrs (name: _: { identityFile = config.sops.secrets."ssh-key/${name}".path; });
      };

      lazygit.enable = true;
    };
  };
}
