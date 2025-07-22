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
    sources = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "sshd"
          "iptables"
          "caddy"
        ]
      );
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    meta.ports.list = [
      cfg.apiPort
      cfg.prometheusPort
    ];

    nixpkgs.overlays = [ inputs.crowdsec.overlays.default ];

    sops.secrets."crowdsec/enrollment-key".owner = user;

    users.groups.caddy.members = lib.mkIf (lib.elem "caddy" cfg.sources) [ user ];

    services.crowdsec = {
      enable = true;
      package = inputs.crowdsec.packages.${pkgs.system}.crowdsec;
      enrollKeyFile = config.sops.secrets."crowdsec/enrollment-key".path;
      settings = {
        api.server.listen_uri = "127.0.0.1:${builtins.toString cfg.apiPort}";
        cscli.prometheus_uri = "http://127.0.0.1:${builtins.toString cfg.prometheusPort}";
      };

      allowLocalJournalAccess = true;
      acquisitions =
        let
          mkAcquisition =
            enable: unit:
            lib.optionalAttrs enable {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=${unit}" ];
              labels.type = "syslog";
            };
        in
        [
          (mkAcquisition (lib.elem "sshd" cfg.sources) "sshd.service")
          (lib.mkIf (lib.elem "caddy" cfg.sources) {
            filenames = [ "${config.services.caddy.logDir}/*.log" ];
            labels.type = "caddy";
          })
          (lib.mkIf (lib.elem "iptables" cfg.sources) {
            source = "journalctl";
            journalctl_filter = [ "-k" ];
            labels.type = "syslog";
          })
        ];
    };

    systemd.services.crowdsec.serviceConfig.ExecStartPre =
      let
        installCollection = collection: ''
          if ! cscli collections list | grep -q "${collection}"; then
            cscli collections install ${collection}
          fi
        '';
      in
      [
        (lib.singleton "crowdsecurity/linux")
        (lib.optional (lib.elem "sshd" cfg.sources) "crowdsecurity/sshd")
        (lib.optional (lib.elem "caddy" cfg.sources) "crowdsecurity/caddy")
        (lib.optional (lib.elem "iptables" cfg.sources) "crowdsecurity/iptables")
      ]
      |> lib.concatLists
      |> lib.map installCollection
      |> lib.concatLines
      |> (text: pkgs.writeShellScript "crowdsec-install-collections" "set -e\n${text}")
      |> lib.mkAfter;
  };
}
