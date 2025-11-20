{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  options.custom.programs.winboat.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.winboat.enable {
    virtualisation.docker.enable = true;
    users.users.seb.extraGroups = [ config.users.groups.docker.name ];

    environment.systemPackages = [ (pkgs-unstable.winboat.override { nodejs_24 = pkgs.nodejs_24; }) ];
  };
}
