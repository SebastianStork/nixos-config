{ config, ... }:
{
  sops.secrets."nextcloud/gmail-password" = { };

  services.nextcloud.settings = {
    mail_smtpmode = "sendmail";
    mail_sendmailmode = "pipe";
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
}
