{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.nightly-maintenance;
in
{
  options.custom.services.nightly-maintenance.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    systemd.services.nixos-upgrade =
      let
        backupUnits =
          config.custom.services.restic.backups
          |> lib.attrValues
          |> lib.filter (backup: backup.enable)
          |> lib.map (backup: "restic-backups-${backup.name}.service");
      in
      {
        description = "Reconcile the system with its deployment target";
        requires = backupUnits;
        after = backupUnits ++ [ "network-online.target" ];
        wants = [ "network-online.target" ];
        restartIfChanged = false;
        path = [
          pkgs.coreutils
          pkgs.nh
          pkgs.nix
          pkgs.systemd
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          IFS= read -r closure < ${config.custom.services.deploy-webhook.deploymentTargetFile}
          nix build --no-link "$closure"
          nh os boot \
            --bypass-root-check \
            --diff never \
            --no-nom \
            --show-activation-logs \
            "$closure"

          booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
          target="$(readlink "$closure"/{initrd,kernel,kernel-modules})"

          if [[ "$booted" == "$target" ]]; then
            nh os switch \
              --bypass-root-check \
              --diff never \
              --no-nom \
              --show-activation-logs \
              "$closure"
          else
            current_time=$(date +%H:%M)
            if [[ "$current_time" > "03:00" && "$current_time" < "05:00" ]]; then
              shutdown --reboot +1
            else
              echo "A reboot is required, but the maintenance window has ended."
            fi
          fi
        '';
      };

    systemd.timers.nixos-upgrade = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:00";
        RandomizedDelaySec = "1h";
        FixedRandomDelay = true;
        Persistent = false;
      };
    };
  };
}
