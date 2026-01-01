{ config, lib, ... }:
let
  cfg = config.custom.services.nebula.node;
in
{
  options.custom.services.nebula.node.sshd = {
    enable = lib.mkEnableOption "" // {
      default = true;
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
    };
  };

  config = lib.mkIf (cfg.enable && cfg.sshd.enable) {
    meta.ports.tcp = [ cfg.sshd.port ];

    services.openssh = {
      enable = true;
      openFirewall = false;
      ports = [ ];
      listenAddresses = lib.singleton {
        addr = cfg.address;
        inherit (cfg.sshd) port;
      };
    };

    systemd.services.sshd = {
      requires = [ "nebula@mesh.service" ];
      after = [ "nebula@mesh.service" ];
    };
  };
}
