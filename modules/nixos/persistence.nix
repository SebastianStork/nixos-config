{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.persistence;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.custom.persistence = {
    enable = lib.mkEnableOption "";
    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.coercedTo lib.types.str (d: { directory = d; }) lib.types.attrs);
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
      ++ config.custom.persistence.directories;

      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };
  };
}
