{ config, lib, ... }:
let
  user = config.users.users.forgejo.name;
in
{
  options.custom.services.forgejo.backups.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.forgejo.backups.enable {
    custom.services.resticBackups.forgejo = {
      inherit user;
      dependentService = "forgejo.service";
      extraConfig.paths = [ config.services.forgejo.stateDir ];
    };
  };
}
