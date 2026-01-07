{
  config,
  self,
  lib,
  ...
}:
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

    services = {
      openssh = {
        enable = true;
        openFirewall = false;
        ports = [ ];
        listenAddresses = lib.singleton {
          addr = cfg.address;
          inherit (cfg.sshd) port;
        };
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      nebula.networks.mesh.firewall.inbound =
        config.custom.services.nebula.peers
        |> lib.filter (node: node.isClient)
        |> lib.map (nebula: {
          inherit (cfg.sshd) port;
          proto = "tcp";
          host = nebula.name;
        });
    };

    systemd.services.sshd = {
      requires = [ "nebula@mesh.service" ];
      after = [ "nebula@mesh.service" ];
    };

    users.users.seb.openssh.authorizedKeys.keyFiles =
      self.nixosConfigurations
      |> lib.filterAttrs (name: _: name != config.networking.hostName)
      |> lib.attrValues
      |> lib.filter (value: value.config |> lib.hasAttr "home-manager")
      |> lib.map (value: value.config.home-manager.users.seb.custom.programs.ssh)
      |> lib.filter (ssh: ssh.enable)
      |> lib.map (ssh: ssh.publicKeyPath);
  };
}
