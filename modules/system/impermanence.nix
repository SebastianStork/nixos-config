{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.custom.impermanence;

  inherit (config.custom) services;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.custom.impermanence.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    fileSystems."/persist".neededForBoot = true;

    environment.persistence."/persist" = {
      hideMounts = true;

      # See https://nixos.org/manual/nixos/stable/#ch-system-state
      directories = [
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/log"

        (lib.optionalString services.tailscale.enable "/var/lib/tailscale")
      ];
    
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };
  };
}
