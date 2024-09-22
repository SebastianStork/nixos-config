{ lib, ... }:
let
  serviceName = lib.last (lib.splitString "/" (builtins.toString ./.)); # Parent directory name
  subdomain = "paper";
in
{
  sops.secrets."container/paperless/admin-password" = { };

  containers.${serviceName}.config =
    { dataDir, ... }:
    {
      imports = [ ./backup.nix ];

      services.paperless = {
        enable = true;
        inherit dataDir;
        passwordFile = "/run/secrets/container/paperless/admin-password";
        settings.PAPERLESS_OCR_LANGUAGE = "deu+eng";
      };

      myConfig.tailscale = {
        inherit subdomain;
        serve = "28981";
      };
    };
}
