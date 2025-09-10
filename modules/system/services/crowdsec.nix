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
  imports = [
    inputs.crowdsec.nixosModules.crowdsec
    inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
  ];

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
      iptables = lib.mkEnableOption "";
      caddy = lib.mkEnableOption "";
      sshd = lib.mkEnableOption "";
    };
    bouncer.firewall = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    meta.ports.tcp.list = [
      cfg.apiPort
      cfg.prometheusPort
    ];

    sops.secrets."crowdsec/enrollment-key".owner = user;

    users.groups.caddy.members = lib.mkIf cfg.sources.caddy [ user ];

    services = {
      crowdsec = {
        enable = true;
        package = inputs.crowdsec.packages.${pkgs.system}.crowdsec;
        enrollKeyFile = config.sops.secrets."crowdsec/enrollment-key".path;
        settings = {
          api.server.listen_uri = "localhost:${builtins.toString cfg.apiPort}";
          cscli.prometheus_uri = "http://localhost:${builtins.toString cfg.prometheusPort}";
        };

        allowLocalJournalAccess = true;
        acquisitions =
          let
            mkJournalAcquisition = unit: {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=${unit}" ];
              labels.type = "syslog";
            };
          in
          [
            (lib.mkIf cfg.sources.iptables {
              source = "journalctl";
              journalctl_filter = [ "-k" ];
              labels.type = "syslog";
            })
            (lib.mkIf cfg.sources.caddy {
              filenames = [ "${config.services.caddy.logDir}/*.log" ];
              labels.type = "caddy";
            })
            (lib.mkIf cfg.sources.sshd (mkJournalAcquisition "sshd.service"))
          ];
      };

      crowdsec-firewall-bouncer = {
        enable = true;
        package = inputs.crowdsec.packages.${pkgs.system}.crowdsec-firewall-bouncer;
        settings = {
          api_key = "cs-firewall-bouncer";
          api_url = "http://localhost:${builtins.toString cfg.apiPort}";
        };
      };
    };

    systemd.services.crowdsec.serviceConfig.ExecStartPre =
      let
        mkScript =
          name: text:
          lib.getExe (
            pkgs.writeShellApplication {
              inherit name text;
            }
          );

        installCollection = collection: ''
          if ! cscli collections list | grep -q "${collection}"; then
            cscli collections install ${collection}
          fi
        '';
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

        bouncerScript = mkScript "crowdsec-add-bouncer" ''
          if ! cscli bouncers list | grep -q "firewall"; then
            cscli bouncers add "firewall" --key "cs-firewall-bouncer"
          fi
        '';
      in
      lib.mkAfter [
        collectionsScript
        bouncerScript
      ];
  };
}
