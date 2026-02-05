{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.custom.services.sshd;
  netCfg = config.custom.networking;
in
{
  options.custom.services.sshd.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    services = {
      openssh = {
        enable = true;
        openFirewall = false;
        ports = lib.mkForce [ ];
        listenAddresses = lib.singleton {
          addr = netCfg.overlay.address;
          port = 22;
        };
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      nebula.networks.mesh.firewall.inbound = lib.singleton {
        port = 22;
        proto = "tcp";
        group = "client";
      };
    };

    systemd.services.sshd = {
      requires = [ netCfg.overlay.systemdUnit ];
      after = [ netCfg.overlay.systemdUnit ];
    };

    users.users.seb.openssh.authorizedKeys.keyFiles =
      self.nixosConfigurations
      |> lib.attrValues
      |> lib.filter (host: host.config.networking.hostName != netCfg.hostName)
      |> lib.filter (host: host.config |> lib.hasAttr "home-manager")
      |> lib.map (host: host.config.home-manager.users.seb.custom.programs.ssh)
      |> lib.filter (ssh: ssh.enable)
      |> lib.map (ssh: ssh.publicKeyPath);
  };
}
