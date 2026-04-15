{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.web-services.anki-outline;

  dataDir = "/var/lib/anki-outline";
in
{
  options.custom.web-services.anki-outline = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "anki-outline/ssh-key".restartUnits = [ "anki-outline.service" ];
        "anki-outline/api-token".restartUnits = [ "anki-outline.service" ];
      };
      templates."anki-outline-config.toml".content = ''
        [outline]
        url = "https://${config.custom.web-services.outline.domain}"
        api_token = "${config.sops.placeholder."anki-outline/api-token"}"
        output_dir = "${dataDir}"
      '';
    };

    systemd.services.anki-outline = {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "multi-user.target" ];
      startAt = "hourly";
      path = [
        pkgs.nix
        pkgs.git
        pkgs.openssh
      ];
      environment.GIT_SSH_COMMAND = "ssh -i ${
        config.sops.secrets."anki-outline/ssh-key".path
      } -o IdentitiesOnly=yes -o StrictHostKeyChecking=no";
      script = "nix run git+ssh://git@github.com/NebelToast/anki_outline --refresh -- -c ${
        config.sops.templates."anki-outline-config.toml".path
      }";
    };

    custom = {
      services.caddy.virtualHosts.${cfg.domain}.extraConfig = ''
        root ${dataDir}
        file_server browse
      '';

      meta.sites.${cfg.domain} = {
        title = "Anki Decks";
        icon = "sh:anki";
      };
    };
  };
}
