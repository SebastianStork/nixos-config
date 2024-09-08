{ config, lib, ... }:
let
  cfg = lib.filterAttrs (_: value: value.enable) config.myConfig.resticBackup;
in
{
  options.myConfig.resticBackup = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "";
          user = lib.mkOption {
            type = lib.types.str;
            default = config.users.users.root.name;
          };
          extraConfig = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };
      }
    );
    default = { };
  };

  config = lib.mkIf (cfg != { }) {
    systemd.tmpfiles.rules = lib.mapAttrsToList (
      name: value: "d /var/cache/restic-backups-${name} 700 ${value.user} ${value.user} -"
    ) cfg;

    users.groups.restic.members = lib.mapAttrsToList (_: value: value.user) cfg;

    sops.secrets = {
      "restic/environment" = {
        mode = "440";
        group = config.users.groups.restic.name;
      };
      "restic/password" = {
        mode = "440";
        group = config.users.groups.restic.name;
      };
    };

    services.restic.backups = lib.mapAttrs (
      name: value:
      {
        inherit (value) user;
        initialize = true;
        repository = "s3:https://s3.eu-central-003.backblazeb2.com/stork-atlas/${name}";
        environmentFile = config.sops.secrets."restic/environment".path;
        passwordFile = config.sops.secrets."restic/password".path;
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 6"
          "--keep-yearly 1"
        ];
      }
      // value.extraConfig
    ) cfg;
  };
}
