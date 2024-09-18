{ lib, ... }:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  subdomain = "paper";
in
{
  containers.${serviceName}.config =
    {
      config,
      dataDir,
      ...
    }:
    {
      imports = [ ./backup.nix ];

      sops.secrets."paperless-admin-password" = { };

      services.paperless = {
        enable = true;
        inherit dataDir;
        passwordFile = config.sops.secrets."paperless-admin-password".path;
        settings.PAPERLESS_OCR_LANGUAGE = "deu+eng";
      };

      myConfig.tailscale = {
        inherit subdomain;
        serve = "28981";
      };
    };
}
