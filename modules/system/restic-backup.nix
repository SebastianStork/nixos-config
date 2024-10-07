{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = lib.filterAttrs (_: value: value.enable) config.myConfig.resticBackup;

  healthchecksEnable = (lib.filterAttrs (_: value: value.healthchecks.enable) cfg) != { };
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
    systemd.tmpfiles.rules =
      (lib.optionals (!config.myConfig.sops.enable) [
        "z /run/secrets/restic/environment 440 root ${config.users.groups.backup.name} -"
        "z /run/secrets/restic/password 440 root ${config.users.groups.backup.name} -"
        "z /run/secrets/healthchecks-ping-key 440 root ${config.users.groups.backup.name} -"
      ])
      ++ lib.mapAttrsToList (
        name: value: "d /var/cache/restic-backups-${name} 700 ${value.user} ${value.user} -"
      ) cfg;

    users.groups.backup.members = builtins.filter (user: user != config.users.users.root.name) (
      lib.mapAttrsToList (_: value: value.user) cfg
    );

    sops.secrets = lib.optionalAttrs config.myConfig.sops.enable (
      let
        resticPermissions = {
          mode = "440";
          group = config.users.groups.backup.name;
        };
      in
      {
        "restic/environment" = resticPermissions;
        "restic/password" = resticPermissions;
        "healthchecks-ping-key" = lib.mkIf healthchecksEnable resticPermissions;
      }
    );

    services.restic.backups = lib.mapAttrs (
      name: value:
      lib.mkMerge [
        {
          inherit (value) user;
          initialize = true;
          repository = "s3:https://s3.eu-central-003.backblazeb2.com/stork-atlas/${name}";
          environmentFile =
            config.sops.secrets."restic/environment".path or "/run/secrets/restic/environment";
          passwordFile = config.sops.secrets."restic/password".path or "/run/secrets/restic/password";
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 5"
            "--keep-monthly 6"
            "--keep-yearly 1"
          ];
        }
        value.extraConfig
      ]
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

      (lib.mkIf healthchecksEnable {
        "healthcheck-ping@" = {
          description = "Pings healthcheck (%i)";
          serviceConfig.Type = "oneshot";
          scriptArgs = "%i";
          script = ''
            ${lib.getExe pkgs.curl} -fsS -m 10 --retry 5  https://hc-ping.com/$(cat ${
              config.sops.secrets."healthchecks-ping-key".path or "/run/secrets/healthchecks-ping-key"
            })/$(echo $1 | tr _ /)
          '';
        };
      })
    ];
  };
}
