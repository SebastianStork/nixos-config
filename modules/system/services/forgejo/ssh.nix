{ config, lib, ... }:
let
  cfg = config.custom.services.forgejo.ssh;
in
{
  options.custom.services.forgejo.ssh = {
    enable = lib.mkEnableOption "";
    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
    };
  };

  config = lib.mkIf cfg.enable {
    meta.ports.tcp.list = [ cfg.port ];

    services.forgejo.settings.server.SSH_PORT = cfg.port;

    services.openssh = {
      enable = true;
      ports = lib.mkForce [ cfg.port ];
      authorizedKeysFiles = lib.mkForce [ "${config.services.forgejo.stateDir}/.ssh/authorized_keys" ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ config.users.users.forgejo.name ];
      };
    };
  };
}
