{
  config,
  pkgs,
  lib,
  ...
}:
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
          healthchecks.enable = lib.mkEnableOption "";
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

    users.groups.backup.members = lib.mapAttrsToList (_: value: value.user) cfg;

    sops.secrets =
      let
        resticPermissions = {
          mode = "440";
          group = config.users.groups.backup.name;
        };
      in
      {
        "restic/environment" = resticPermissions;
        "restic/password" = resticPermissions;

        "healthchecks-ping-key" = lib.mkIf (
          (lib.filterAttrs (_: value: value.healthchecks.enable) cfg) != { }
        ) resticPermissions;
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

    systemd.services = lib.mkMerge [
      (lib.mapAttrs' (
        name: _:
        lib.nameValuePair "restic-backups-${name}" {
          wants = [ "healthcheck-ping@${name}-backup_start.service" ];
          onSuccess = [ "healthcheck-ping@${name}-backup.service" ];
          onFailure = [ "healthcheck-ping@${name}-backup_fail.service" ];
        }
      ) (lib.filterAttrs (_: value: value.healthchecks.enable) cfg))

      (lib.mkIf ((lib.filterAttrs (_: value: value.healthchecks.enable) cfg) != { }) {
        "healthcheck-ping@" = {
          description = "Pings healthcheck (%i)";
          serviceConfig.Type = "oneshot";
          scriptArgs = "%i";
          script = ''
            ${lib.getExe pkgs.curl} -fsS -m 10 --retry 5  https://hc-ping.com/$(cat ${
              config.sops.secrets."healthchecks-ping-key".path
            })/$(echo $1 | tr _ /)
          '';
        };
      })
    ];
  };
}
