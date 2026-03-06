{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.comin;

  postDeploymentScript =
    pkgs.writeShellApplication {
      name = "comin-post-deployment";
      runtimeInputs = [ pkgs.git ];
      text = ''
        if [[ "$COMIN_STATUS" != "done" ]]; then
          echo "Deployment not successful (status: $COMIN_STATUS), skipping branch update"
          exit 0
        fi

        token=$(cat "${config.sops.secrets."git/push-token".path}")
        repo_url="https://x-access-token:$token@github.com/SebastianStork/nixos-config.git"

        git push --force "$repo_url" "$COMIN_GIT_SHA:refs/heads/deployed/$COMIN_HOSTNAME"

        echo "Updated deployed/$COMIN_HOSTNAME to $COMIN_GIT_SHA"
      '';
    }
    |> lib.getExe;
in
{
  imports = [ inputs.comin.nixosModules.comin ];

  options.custom.services.comin = {
    enable = lib.mkEnableOption "";
    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 4243;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."git/push-token" = { };

    services.comin = {
      enable = true;
      remotes = lib.singleton {
        name = "origin";
        url = "https://github.com/SebastianStork/nixos-config.git";
        branches.main.name = "deploy";
      };
      exporter = {
        listen_address = "127.0.0.1";
        port = cfg.metricsPort;
      };
      postDeploymentCommand = postDeploymentScript;
    };
  };
}
