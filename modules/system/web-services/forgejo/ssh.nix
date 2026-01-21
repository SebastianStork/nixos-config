{ config, lib, ... }:
let
  cfg = config.custom.web-services.forgejo.ssh;
in
{
  options.custom.web-services.forgejo.ssh = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo.settings.server.SSH_PORT = cfg.port;

    services.openssh = {
      enable = true;
      ports = lib.mkForce [ cfg.port ];
      authorizedKeysFiles = lib.mkForce [ "${config.services.forgejo.stateDir}/.ssh/authorized_keys" ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ config.services.forgejo.user ];
      };
    };
  };
}
