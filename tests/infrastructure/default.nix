{
  inputs,
  self,
  lib,
  ...
}:
{
  defaults =
    { nodes, config, ... }:
    {
      imports = [ self.nixosModules.default ];

      _module.args.allHosts = nodes |> lib.mapAttrs (_: node: { config = node; });

      users = {
        mutableUsers = false;
        users.seb = {
          isNormalUser = true;
          password = "seb";
          extraGroups = [ "wheel" ];
        };
      };

      custom = {
        networking.overlay.networkCidr = lib.mkForce "10.10.10.0/24";
        services.nebula = {
          caCertificatePath = ./keys/ca.crt;
          certificatePath = ./keys/${config.networking.hostName}.crt;
          privateKeyPath = ./keys/${config.networking.hostName}.key;
        };
      };

      services.resolved.dnssec = lib.mkForce "false";
    };

  node.specialArgs = { inherit inputs self; };

  nodes = {
    lighthouse = {
      custom = {
        networking = {
          overlay = {
            address = "10.10.10.1";
            isLighthouse = true;
            role = "server";
          };
          underlay = {
            interface = "eth1";
            cidr = "192.168.0.1/16";
            isPublic = true;
          };
        };

        services.dns.enable = true;
      };
    };

    server = {
      custom = {
        networking = {
          overlay = {
            address = "10.10.10.2";
            role = "server";
          };
          underlay = {
            interface = "eth1";
            cidr = "192.168.0.2/16";
            isPublic = true;
          };
        };

        services.sshd.enable = true;
      };

      users.users.seb.openssh.authorizedKeys.keyFiles = [ ./keys/client-ssh.pub ];
      environment.etc."ssh-key" = {
        source = ./keys/server-ssh;
        mode = "0600";
      };
    };

    client = {
      custom.networking = {
        overlay = {
          address = "10.10.10.3";
          role = "client";
        };
        underlay = {
          interface = "eth1";
          cidr = "192.168.0.3/16";
        };
      };

      users.users.seb.openssh.authorizedKeys.keyFiles = [ ./keys/server-ssh.pub ];
      environment.etc."ssh-key" = {
        source = ./keys/client-ssh;
        mode = "0600";
      };
    };
  };

  testScript =
    { nodes, ... }:
    let
      lighthouseNetCfg = nodes.lighthouse.custom.networking.overlay;
      serverNetCfg = nodes.server.custom.networking.overlay;
      clientNetCfg = nodes.client.custom.networking.overlay;

      sshOptions = "-i /etc/ssh-key -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    in
    ''
      start_all()

      lighthouse.wait_for_unit("${lighthouseNetCfg.systemdUnit}")
      server.wait_for_unit("${serverNetCfg.systemdUnit}")
      client.wait_for_unit("${clientNetCfg.systemdUnit}")
      lighthouse.wait_for_unit("unbound.service")
      server.wait_for_unit("sshd.service")

      with subtest("Overlay connectivity between nodes"):
        client.succeed("ping -c 1 ${serverNetCfg.address}")
        server.succeed("ping -c 1 ${clientNetCfg.address}")

      with subtest("DNS resolution of overlay hostnames"):
        client.succeed("ping -c 1 ${serverNetCfg.fqdn}")
        server.succeed("ping -c 1 ${clientNetCfg.fqdn}")

      with subtest("SSH access restricted by role"):
        client.succeed("ssh ${sshOptions} seb@${serverNetCfg.fqdn} 'echo Hello'")
        server.fail("ssh ${sshOptions} seb@${clientNetCfg.fqdn} 'echo Hello'")
    '';
}
