{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.crowdsec;

  user = config.users.users.crowdsec.name;
in
{
  imports = [ inputs.crowdsec.nixosModules.crowdsec ];

  options.custom.services.crowdsec = {
    enable = lib.mkEnableOption "";
    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
    prometheusPort = lib.mkOption {
      type = lib.types.port;
      default = 6060;
    };
    sources = {
      iptables = lib.mkEnableOption "" // {
        default = true;
      };
      caddy = lib.mkEnableOption "" // {
        default = config.services.caddy.enable;
      };
      sshd = lib.mkEnableOption "" // {
        default = config.services.openssh.enable;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    meta.ports.tcp = [
      cfg.apiPort
      cfg.prometheusPort
    ];

    sops.secrets."crowdsec/enrollment-key" = {
      owner = user;
      restartUnits = [ "crowdsec.service" ];
    };

    users.groups.caddy.members = lib.mkIf cfg.sources.caddy [ user ];

    services.crowdsec = {
      enable = true;
      package = inputs.crowdsec.packages.${pkgs.system}.crowdsec;
      enrollKeyFile = config.sops.secrets."crowdsec/enrollment-key".path;
      settings = {
        api.server.listen_uri = "localhost:${toString cfg.apiPort}";
        cscli.prometheus_uri = "http://localhost:${toString cfg.prometheusPort}";
        prometheus = {
          listen_addr = "localhost";
          listen_port = cfg.prometheusPort;
        };
      };

      allowLocalJournalAccess = true;
      acquisitions = [
        (lib.mkIf cfg.sources.iptables {
          source = "journalctl";
          journalctl_filter = [ "-k" ];
          labels.type = "syslog";
        })
        (lib.mkIf cfg.sources.caddy {
          filenames = [ "${config.services.caddy.logDir}/*.log" ];
          labels.type = "caddy";
        })
        (lib.mkIf cfg.sources.sshd {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        })
      ];
    };

    systemd.services.crowdsec.serviceConfig = {
      # Fix journalctl acquisitions
      PrivateUsers = false;

      ExecStartPre =
        let
          installCollection = collection: ''
            if ! cscli collections list | grep -q "${collection}"; then
              cscli collections install ${collection}
            fi
          '';
          mkScript =
            name: text:
            lib.getExe (
              pkgs.writeShellApplication {
                inherit name text;
              }
            );
          collectionsScript =
            [
              (lib.singleton "crowdsecurity/linux")
              (lib.optional cfg.sources.iptables "crowdsecurity/iptables")
              (lib.optional cfg.sources.caddy "crowdsecurity/caddy")
              (lib.optional cfg.sources.sshd "crowdsecurity/sshd")
            ]
            |> lib.concatLists
            |> lib.map installCollection
            |> lib.concatLines
            |> mkScript "crowdsec-install-collections";
        in
        lib.mkAfter collectionsScript;
    };

    custom.persistence.directories = [ "/var/lib/crowdsec" ];
  };
}
