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
  options.custom.services.nebula.node.sshd.enable = lib.mkEnableOption "" // {
    default = true;
  };

  config = lib.mkIf (cfg.enable && cfg.sshd.enable) {
    meta.ports.tcp = [ 22 ];

    services = {
      openssh = {
        enable = true;
        openFirewall = false;
        ports = [ ];
        listenAddresses = lib.singleton {
          addr = cfg.address;
          port = 22;
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
          port = 22;
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
