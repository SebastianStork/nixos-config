{
  services.paperless = {
    enable = true;
    dataDir = "/data/paperless";
    passwordFile = "/run/secrets/paperless-admin-password";
    settings.PAPERLESS_OCR_LANGUAGE = "deu+eng";
  };
}
