{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.forgejo-runner;
in
{
  options.custom.services.forgejo-runner = {
    enable = lib.mkEnableOption "";
    forgejoUrl = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    capacity = lib.mkOption {
      type = lib.types.int;
    };
    extraLabels = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets."forgejo-runner/token" = { };
      templates."forgejo-runner.env".content = "TOKEN=${config.sops.placeholder."forgejo-runner/token"}";
    };

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.default = {
        enable = true;
        name = config.networking.hostName;
        url = cfg.forgejoUrl;
        tokenFile = config.sops.templates."forgejo-runner.env".path;
        settings.runner.capacity = cfg.capacity;
        labels = [ "nixos:host" ] ++ (cfg.extraLabels |> map (label: "${label}:host"));
        hostPackages = lib.mkOptionDefault [
          pkgs.jq
          pkgs.nix
          pkgs.nix-fast-build
        ];
      };
    };

    nix.settings.allowed-users = [ config.systemd.services."gitea-runner-default".serviceConfig.User ];

    custom.persistence.directories = [ "/var/lib/private/gitea-runner" ];
  };
}
