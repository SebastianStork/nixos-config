{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.radicale;
in
{
  options.custom.services.radicale = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5232;
    };
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops = {
      secrets."radicale/admin-password" = { };
      templates."radicale/htpasswd" = {
        owner = config.users.users.radicale.name;
        content = "seb:${config.sops.placeholder."radicale/admin-password"}";
      };
    };

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = "localhost:${builtins.toString cfg.port}";
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.templates."radicale/htpasswd".path;
          htpasswd_encryption = "plain";
        };

        storage.hook =
          let
            hookScript = pkgs.writeShellApplication {
              name = "radicale-git-hook";
              runtimeInputs = [
                pkgs.git
                pkgs.gawk
                (pkgs.python3.withPackages (
                  python-pkgs: with python-pkgs; [
                    dateutil
                    vobject
                  ]
                ))
              ];
              text = ''
                readonly username="$1"

                git add -A
                if ! git diff --cached --quiet; then
                  git commit --message "Changes by $username"
                fi
              '';
            };
          in
          "${lib.getExe hookScript} %(user)s";
      };
    };

    systemd.services.radicale.serviceConfig.ExecStartPre =
      let
        gitignore = builtins.toFile "radicale-collection-gitignore" ''
          .Radicale.cache
          .Radicale.lock
          .Radicale.tmp-*
        '';
      in
      lib.getExe (
        pkgs.writeShellApplication {
          name = "radicale-git-init";
          runtimeInputs = [ pkgs.git ];
          text = ''
            cd ${config.services.radicale.settings.storage.filesystem_folder}
            if [[ ! -e .git ]]; then
              git init --initial-branch main
            fi

            git config user.name "Radicale"
            git config user.email "radicale@${config.networking.hostName}"

            cat ${gitignore} > .gitignore
            git add .gitignore
            if ! git diff --cached --quiet; then
              git commit --message "Update .gitignore"
            fi
          '';
        }
      );
  };
}
