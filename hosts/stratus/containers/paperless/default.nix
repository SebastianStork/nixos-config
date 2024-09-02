{
  containers.paperless.config =
    {
      config,
      dataDir,
      ...
    }:
    {
      sops.secrets."paperless-admin-password" = { };

      services.paperless = {
        enable = true;
        inherit dataDir;
        passwordFile = config.sops.secrets."paperless-admin-password".path;
        settings.PAPERLESS_OCR_LANGUAGE = "deu+eng";
      };

      myConfig.tailscale.serve = "28981";
    };
}
