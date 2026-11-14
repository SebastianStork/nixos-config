{ config, lib, ... }:
{
  options.custom.services.nightly-maintenance.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.nightly-maintenance.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "git+https://codeberg.org/SebastianStork/nixos-config";
      dates = "03:00";
      randomizedDelaySec = "1h";
      fixedRandomDelay = true;
      allowReboot = true;
    };

    systemd.services.nixos-upgrade =
      let
        backupUnits =
          config.custom.services.restic.backups
          |> lib.filterAttrs (_: backup: backup.enable)
          |> lib.attrNames
          |> lib.map (name: "restic-backups-${name}.service");
      in
      {
        requires = backupUnits;
        after = backupUnits;
      };
  };
}
