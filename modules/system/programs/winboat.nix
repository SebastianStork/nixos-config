{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  options.custom.programs.winboat.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.programs.winboat.enable {
    virtualisation.docker.enable = true;
    users.users.seb.extraGroups = [ config.users.groups.docker.name ];

    environment.systemPackages = [
      pkgs.docker-compose
      pkgs.freerdp
      inputs.winboat.packages.${pkgs.system}.winboat
    ];
  };
}
