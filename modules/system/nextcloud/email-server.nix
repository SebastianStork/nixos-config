{ config, lib, ... }:
{
  options.myConfig.nextcloud.emailServer.enable = lib.mkEnableOption "";

  config = lib.mkIf config.myConfig.nextcloud.emailServer.enable {
    sops.secrets."nextcloud/gmail-password" = {
      owner = config.services.nextcloud.config.dbname;
      group = config.services.nextcloud.config.dbuser;
    };

    programs.msmtp = {
      enable = true;
      accounts.default = {
        auth = true;
        tls = true;
        host = "smtp.gmail.com";
        port = "587";
        user = "nextcloud.stork";
        from = "nextcloud.stork@gmail.com";
        passwordeval = "cat ${config.sops.secrets."nextcloud/gmail-password".path}";
      };
    };

    services.nextcloud.settings = {
      mail_smtpmode = "sendmail";
      mail_sendmailmode = "pipe";
    };
  };
}
