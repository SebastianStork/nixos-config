{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.impermanence;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.custom = {
    impermanence.enable = lib.mkEnableOption "";
    persist.directories = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems."/persist".neededForBoot = true;

    security.sudo.extraConfig = "Defaults lecture=never";

    environment.persistence."/persist" = {
      hideMounts = true;

      # See https://nixos.org/manual/nixos/stable/#ch-system-state
      directories = [
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/log"
      ]
      ++ config.custom.persist.directories;
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };
  };
}
