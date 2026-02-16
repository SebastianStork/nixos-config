{
  inputs,
  self,
  lib,
  ...
}:
{
  node.specialArgs = { inherit inputs self; };

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
          openssh.authorizedKeys.keyFiles = lib.mkIf config.custom.services.sshd.enable [
            ./keys/server-ssh.pub
            ./keys/client1-ssh.pub
            ./keys/client2-ssh.pub
          ];
        };
      };

      environment.etc."ssh-key" = lib.mkIf (lib.pathExists ./keys/${config.networking.hostName}-ssh) {
        source = ./keys/${config.networking.hostName}-ssh;
        mode = "0600";
      };

      custom.services.nebula = {
        caCertificatePath = ./keys/ca.crt;
        certificatePath = ./keys/${config.networking.hostName}.crt;
        privateKeyPath = ./keys/${config.networking.hostName}.key;
      };

      services.resolved.dnssec = lib.mkForce "false";
    };

  nodes = {
    lighthouse = {
      custom = {
        networking = {
          overlay = {
            address = "10.254.250.1";
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
            address = "10.254.250.2";
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
    };

    client1 =
      { pkgs, ... }:
      {
        custom = {
          networking = {
            overlay = {
              address = "10.254.250.3";
              role = "client";
            };
            underlay = {
              interface = "eth1";
              cidr = "192.168.0.3/16";
            };
          };
        };

        environment.systemPackages = [ pkgs.openssh ];
      };

    client2 = {
      custom = {
        networking = {
          overlay = {
            address = "10.254.250.4";
            role = "client";
          };
          underlay = {
            interface = "eth1";
            cidr = "192.168.0.4/16";
          };
        };

        services.sshd.enable = true;
      };
    };
  };

  testScript =
    { nodes, ... }:
    let
      lighthouseNetCfg = nodes.lighthouse.custom.networking;
      serverNetCfg = nodes.server.custom.networking;
      client1NetCfg = nodes.client1.custom.networking;
      client2NetCfg = nodes.client2.custom.networking;

      sshOptions = "-i /etc/ssh-key -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    in
    ''
      start_all()

      lighthouse.wait_for_unit("${lighthouseNetCfg.overlay.systemdUnit}")
      server.wait_for_unit("${serverNetCfg.overlay.systemdUnit}")
      client1.wait_for_unit("${client1NetCfg.overlay.systemdUnit}")
      client2.wait_for_unit("${client2NetCfg.overlay.systemdUnit}")

      lighthouse.wait_for_unit("unbound.service")
      lighthouse.wait_for_open_port(53, "${lighthouseNetCfg.overlay.address}")

      server.wait_for_unit("sshd.service")
      client2.wait_for_unit("sshd.service")
      server.wait_for_open_port(22, "${serverNetCfg.overlay.address}")
      client2.wait_for_open_port(22, "${client2NetCfg.overlay.address}")

      with subtest("Overlay connectivity between nodes"):
        client1.succeed("ping -c 1 ${serverNetCfg.overlay.address}")
        client1.succeed("ping -c 1 ${client2NetCfg.overlay.address}")
        server.succeed("ping -c 1 ${client1NetCfg.overlay.address}")

      with subtest("DNS resolution of FQDNs"):
        client1.succeed("ping -c 1 ${serverNetCfg.overlay.fqdn}")
        client1.succeed("ping -c 1 ${client2NetCfg.overlay.fqdn}")
        server.succeed("ping -c 1 ${client1NetCfg.overlay.fqdn}")

      with subtest("SSH access restricted by role"):
        client1.succeed("ssh ${sshOptions} seb@${serverNetCfg.overlay.fqdn} 'echo Hello'")
        client1.succeed("ssh ${sshOptions} seb@${client2NetCfg.overlay.fqdn} 'echo Hello'")
        server.fail("ssh ${sshOptions} seb@${client2NetCfg.overlay.fqdn} 'echo Hello'")
    '';
}
