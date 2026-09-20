{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.rss2email;

  dataDir = "/var/lib/rss2email";

  package = pkgs.rss2email.overridePythonAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./rss2email.patch ];
  });

  defaultsFile =
    {
      DEFAULT = {
        inherit (cfg) from to;
        force-from = "True";
        html-mail = "True";
        multipart-html = "False";
        post-process = "rss2email.post_process.link_only process";
      };
    }
    |> lib.generators.toINI { }
    |> pkgs.writeText "rss2email-defaults.ini";

  r2e = pkgs.writeShellApplication {
    name = "r2e";
    text = ''
      if [[ "$(${lib.getExe' pkgs.coreutils "id"} -un)" != rss2email ]]; then
        exec ${config.security.wrapperDir}/sudo --user=rss2email "$0" "$@"
      fi

      umask 077
      exec ${lib.getExe package} \
        --config ${defaultsFile} \
        --config ${dataDir}/feeds.ini \
        --data ${dataDir}/db.json \
        "$@"
    '';
  };
in
{
  options.custom.services.rss2email = {
    enable = lib.mkEnableOption "";
    from = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
    to = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "msmtp/mailbox/user".owner = config.users.users.rss2email.name;
      "msmtp/mailbox/password".owner = config.users.users.rss2email.name;
    };

    programs.msmtp = {
      enable = true;
      setSendmail = false;
      accounts.rss2email = {
        host = "smtp.mailbox.org";
        port = 587;
        auth = true;
        tls = true;
        inherit (cfg) from;
        eval = pkgs.writeShellScript "msmtp-load-user" ''
          printf 'user %s\n' "$(${lib.getExe' pkgs.coreutils "cat"} ${
            config.sops.secrets."msmtp/mailbox/user".path
          })"
        '';
        passwordeval = "${lib.getExe' pkgs.coreutils "cat"} ${
          config.sops.secrets."msmtp/mailbox/password".path
        }";
        allow_from_override = false;
        set_from_header = "on";
      };
    };

    users = {
      users.rss2email = {
        isSystemUser = true;
        group = config.users.groups.rss2email.name;
      };
      groups.rss2email = { };
    };

    environment.systemPackages = [ r2e ];

    systemd = {
      tmpfiles.rules = [
        "d ${dataDir} 0700 ${config.users.users.rss2email.name} ${config.users.users.rss2email.name} -"
      ];

      services.rss2email = {
        description = "Email RSS feed entries";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = lib.singleton (
          pkgs.writeShellScriptBin "sendmail" ''
            exec ${lib.getExe config.programs.msmtp.package} --account=rss2email "$@"
          ''
        );
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe r2e} run";
          User = config.users.users.rss2email.name;
          Group = config.users.groups.rss2email.name;
          StateDirectory = "rss2email";
          StateDirectoryMode = "0700";
        };
      };

      timers.rss2email = {
        wantedBy = [ "timers.target" ];
        timerConfig.OnUnitActiveSec = "1h";
      };
    };

    custom.persistence.directories = [ dataDir ];
  };
}
