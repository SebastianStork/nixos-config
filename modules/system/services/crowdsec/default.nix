{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.crowdsec;
in
{
  imports = [ inputs.crowdsec.nixosModules.crowdsec ];

  options.custom.services.crowdsec = {
    enable = lib.mkEnableOption "";
    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
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
    nixpkgs.overlays = [ inputs.crowdsec.overlays.default ];

    sops.secrets."crowdsec/enrollment-key".owner = config.users.users.crowdsec.name;

    services.crowdsec = {
      enable = true;
      package = inputs.crowdsec.packages.${pkgs.system}.crowdsec;
      enrollKeyFile = config.sops.secrets."crowdsec/enrollment-key".path;
      settings = {
        api.server.listen_uri = "127.0.0.1:${toString cfg.apiPort}";
      };

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
          (mkAcquisition (lib.elem "caddy" cfg.sources) "caddy.service")
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
        "crowdsecurity/linux"
        (lib.optional (lib.elem "sshd" cfg.sources) "crowdsecurity/sshd")
        (lib.optional (lib.elem "caddy" cfg.sources) "crowdsecurity/caddy")
        (lib.optional (lib.elem "iptables" cfg.sources) "crowdsecurity/iptables")
      ]
      |> lib.flatten
      |> lib.map installCollection
      |> lib.concatLines
      |> (text: pkgs.writeShellScript "crowdsec-install-collections" "set -e\n${text}")
      |> lib.mkAfter;
  };
}
