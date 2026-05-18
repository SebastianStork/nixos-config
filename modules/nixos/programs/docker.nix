{ config, lib, ... }:
{
  options.custom.programs.docker.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.docker.enable {
    virtualisation.docker.enable = true;
    users.users.seb.extraGroups = [ config.users.groups.docker.name ];
  };
}
