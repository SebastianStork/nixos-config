{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.nightly-maintenance;
  inherit (config.custom.services.deploy-webhook) deploymentTargetFile;
  deploymentRepository = "${deploymentTargetFile}.git";

  syncDeploymentTarget = pkgs.writeShellApplication {
    name = "sync-deployment-target";
    runtimeInputs = [ pkgs.git ];
    text = ''
      export GIT_DIR=${deploymentRepository}

      if [[ ! -d "$GIT_DIR" ]]; then
        git init --bare
      fi
      git fetch --force https://codeberg.org/SebastianStork/nixos-config main
      git update-ref refs/heads/deployment-target "$(<${deploymentTargetFile})"
    '';
  };
in
{
  options.custom.services.nightly-maintenance.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "git+file://${deploymentRepository}?ref=deployment-target";
      dates = "03:00";
      randomizedDelaySec = "1h";
      fixedRandomDelay = true;
      allowReboot = true;
      rebootWindow = {
        lower = "03:00";
        upper = "05:00";
      };
      persistent = false;
    };

    systemd.services.nixos-upgrade =
      let
        backupUnits =
          config.custom.services.restic.backups
          |> lib.attrValues
          |> lib.filter (backup: backup.enable)
          |> lib.map (backup: "restic-backups-${backup.name}.service");
      in
      {
        requires = backupUnits;
        after = backupUnits;
        serviceConfig.ExecStartPre = lib.getExe syncDeploymentTarget;
      };
  };
}
