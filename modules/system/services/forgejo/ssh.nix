{ config, lib, ... }:
{
  options.custom.services.forgejo.ssh.enable = lib.mkEnableOption "";

  config = lib.mkIf config.custom.services.forgejo.ssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ config.users.users.forgejo.name ];
      };
    };
  };
}
