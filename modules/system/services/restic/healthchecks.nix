{
  config,
  pkgs,
  lib,
  ...
}:
let
  backupsWithHealthchecks =
    config.custom.services.restic.backups
    |> lib.attrValues
    |> lib.filter (backup: backup.enable && backup.doHealthchecks);
in
{
  options.custom.services.restic.backups = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.doHealthchecks = lib.mkEnableOption "" // {
          default = true;
        };
      }
    );
  };

  config = lib.mkIf (backupsWithHealthchecks != [ ]) {
    sops.secrets."healthchecks/ping-key" = { };

    systemd.services = {
      "healthcheck-ping@" = {
        description = "Pings healthcheck (%i)";
        serviceConfig.Type = "oneshot";
        scriptArgs = "%i";
        script = ''
          ping_key="$(cat ${config.sops.secrets."healthchecks/ping-key".path})"
          slug="$(echo "$1" | tr _ /)"

          ${lib.getExe pkgs.curl} \
            --fail \
            --silent \
            --show-error \
            --max-time 10 \
            --retry 5 "https://hc-ping.com/$ping_key/$slug?create=1"
        '';
      };
    }
    // (
      backupsWithHealthchecks
      |> lib.map (backup: {
        name = "restic-backups-${backup.name}";
        value = {
          wants = [ "healthcheck-ping@${backup.name}-backup_start.service" ];
          onSuccess = [ "healthcheck-ping@${backup.name}-backup.service" ];
          onFailure = [ "healthcheck-ping@${backup.name}-backup_fail.service" ];
        };
      })
      |> lib.listToAttrs
    );
  };
}
