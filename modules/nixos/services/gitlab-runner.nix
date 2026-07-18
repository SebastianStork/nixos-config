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
    maxConcurrentJobs = lib.mkOption {
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
      clear-docker-cache = {
        enable = true;
        flags = [ "-af" ];
      };
      settings.concurrent = cfg.maxConcurrentJobs;
      services.default = {
        description = config.networking.hostName;
        authenticationTokenConfigFile = config.sops.templates."gitlab-runner.env".path;
        requestConcurrency = cfg.maxConcurrentJobs;
        executor = "docker";
        dockerImage = "docker:latest";
        dockerVolumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/cache"
        ];
      };
    };

    custom.persistence.directories = [
      "/var/lib/private/gitlab-runner"
      "/var/lib/docker"
    ];
  };
}
