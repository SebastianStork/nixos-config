{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.forgejo-runner;

  hostPackages = with pkgs; [
    bash
    coreutils
    curl
    gawk
    gitMinimal
    gnused
    nodejs
    wget
    jq
    nix
    nix-fast-build
  ];
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
      default = 3;
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
        labels = [ "nixos:host" ];
        inherit hostPackages;
      };
    };

    nix.settings.allowed-users = [ config.systemd.services."gitea-runner-default".serviceConfig.User ];
  };
}
