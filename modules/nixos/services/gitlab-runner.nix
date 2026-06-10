{ config, lib, ... }:
let
  cfg = config.custom.services.gitlab-runner;
in
{
  options.custom.services.gitlab-runner = {
    enable = lib.mkEnableOption "";
    gitlabUrl = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    concurrent = lib.mkOption {
      type = lib.types.int;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets."gitlab-runner/token" = { };
      templates."gitlab-runner.env".content = ''
        CI_SERVER_URL=${cfg.gitlabUrl}
        CI_SERVER_TOKEN=${config.sops.placeholder."gitlab-runner/token"}
      '';
    };

    services.gitlab-runner = {
      enable = true;
      settings.concurrent = cfg.concurrent;
      services.default = {
        description = config.networking.hostName;
        authenticationTokenConfigFile = config.sops.templates."gitlab-runner.env".path;
        requestConcurrency = cfg.concurrent;
        executor = "docker";
        dockerImage = "docker:latest";
        dockerVolumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/cache"
        ];
        registrationFlags = [ "--docker-network-mode=bridge" ];
      };
    };

    custom.persistence.directories = [ "/var/lib/private/gitlab-runner" ];
  };
}
