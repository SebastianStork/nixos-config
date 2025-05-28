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
        prometheus.enabled = false;
      };

      acquisitions = [
        (lib.mkIf (lib.elem "iptables" cfg.sources) {
          source = "journalctl";
          journalctl_filter = [ "-k" ];
          labels.type = "syslog";
        })
        (lib.mkIf (lib.elem "caddy" cfg.sources) {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=caddy.service" ];
          labels.type = "syslog";
        })
      ];
    };

    systemd.services.crowdsec.preStart =
      let
        collections = lib.flatten [
          "crowdsecurity/linux"
          (lib.optional (lib.elem "iptables" cfg.sources) "crowdsecurity/iptables")
          (lib.optional (lib.elem "caddy" cfg.sources) "crowdsecurity/caddy")
        ];
        addCollection = collection: ''
          if ! cscli collections list | grep -q "${collection}"; then
            cscli collections install ${collection}
          fi
        '';
      in
      collections |> lib.map addCollection |> lib.concatLines;
  };
}
