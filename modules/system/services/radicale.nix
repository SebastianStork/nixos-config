{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.radicale;

  dataDir = config.services.radicale.settings.storage.filesystem_folder;
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
    doBackups = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    meta = {
      domains.list = [ cfg.domain ];
      ports.tcp.list = [ cfg.port ];
    };

    sops.secrets."radicale/htpasswd" = {
      owner = config.users.users.radicale.name;
      restartUnits = [ "radicale.service" ];
    };

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = "localhost:${builtins.toString cfg.port}";
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.secrets."radicale/htpasswd".path;
          htpasswd_encryption = "bcrypt";
        };
        storage.filesystem_folder = "/var/lib/radicale/collections";

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
                username="$1"
                create_birthday_calendar="${inputs.radicale-birthday-calendar}/create_birthday_calendar.py"

                git status --porcelain | awk '{print $2}' | python3 $create_birthday_calendar

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
        gitignore = pkgs.writeText "radicale-collection-gitignore" ''
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
            cd ${dataDir}

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

    custom = {
      services.resticBackups.radicale = lib.mkIf cfg.doBackups {
        conflictingService = "radicale.service";
        paths = [ dataDir ];
      };
      persist.directories = [ dataDir ];
    };
  };
}
