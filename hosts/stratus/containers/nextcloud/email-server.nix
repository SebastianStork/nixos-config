{
  systemd.tmpfiles.rules = [ "z /run/secrets/nextcloud/gmail-password 400 nextcloud nextcloud -" ];

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
      passwordeval = "cat /run/secrets/nextcloud/gmail-password";
    };
  };
}
