{
  config,
  pkgs,
  lib,
  ...
}:
let
  backupsWithHealthchecks =
    config.custom.services.resticBackups
    |> lib.filterAttrs (_: value: value.enable)
    |> lib.filterAttrs (_: value: value.healthchecks.enable);
in
{
  options.custom.services.resticBackups = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.healthchecks.enable = lib.mkEnableOption "" // {
          default = true;
        };
      }
    );
  };

  config = lib.mkIf (backupsWithHealthchecks != { }) {
    sops.secrets."healthchecks-ping-key" = { };

    systemd.services = lib.mkMerge [
      {
        "healthcheck-ping@" = {
          description = "Pings healthcheck (%i)";
          serviceConfig.Type = "oneshot";
          scriptArgs = "%i";
          script = ''
            ${lib.getExe pkgs.curl} --fail --silent --show-error --max-time 10 --retry 5  https://hc-ping.com/$(cat ${
              config.sops.secrets."healthchecks-ping-key".path
            })/$(echo $1 | tr _ /)
          '';
        };
      }

      (
        backupsWithHealthchecks
        |> lib.mapAttrs' (
          name: _:
          lib.nameValuePair "restic-backups-${name}" {
            wants = [ "healthcheck-ping@${name}-backup_start.service" ];
            onSuccess = [ "healthcheck-ping@${name}-backup.service" ];
            onFailure = [ "healthcheck-ping@${name}-backup_fail.service" ];
          }
        )
      )
    ];
  };
}
