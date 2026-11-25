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

          booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
          target="$(readlink "$closure"/{initrd,kernel,kernel-modules})"

          mode=boot
          if [[ "$booted" == "$target" ]]; then
            mode=switch
          fi

          nh os "$mode" \
            --bypass-root-check \
            --diff never \
            --no-nom \
            --show-activation-logs \
            "$closure"

          if [[ "$mode" == boot ]]; then
            shutdown --reboot +1
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
