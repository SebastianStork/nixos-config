{
  lib,
  ...
}:
{
  defaults =
    { config, ... }:
    {
      users.users.seb.openssh.authorizedKeys.keyFiles = lib.mkIf config.custom.services.sshd.enable [
        ./keys/server/ssh.pub
        ./keys/client1/ssh.pub
        ./keys/client2/ssh.pub
      ];

      environment.etc."ssh-key" = lib.mkIf (lib.pathExists ./keys/${config.networking.hostName}/ssh) {
        source = ./keys/${config.networking.hostName}/ssh;
        mode = "0600";
      };
    };

  nodes = {
    server = {
      custom = {
        networking = {
          overlay = {
            address = "10.254.250.2";
            isLighthouse = true;
            role = "server";
          };
          underlay = {
            cidr = "192.168.0.2/16";
            isPublic = true;
          };
        };

        services = {
          recursive-nameserver.enable = true;
          private-nameserver.enable = true;

          sshd.enable = true;
        };
      };
    };

    client1 =
      { pkgs, ... }:
      {
        custom.networking = {
          overlay = {
            address = "10.254.250.3";
            role = "client";
          };
          underlay.cidr = "192.168.0.3/16";
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
          underlay.cidr = "192.168.0.4/16";
        };

        services.sshd.enable = true;
      };
    };
  };

  testScript =
    { nodes, ... }:
    let
      serverNetCfg = nodes.server.custom.networking;
      client1NetCfg = nodes.client1.custom.networking;
      client2NetCfg = nodes.client2.custom.networking;

      ssh = "timeout 10 ssh -i /etc/ssh-key -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    in
    ''
      start_all()

      with subtest("Overlay readiness"):
        server.wait_for_unit("${serverNetCfg.overlay.systemdUnit}")
        client1.wait_for_unit("${client1NetCfg.overlay.systemdUnit}")
        client2.wait_for_unit("${client2NetCfg.overlay.systemdUnit}")

      with subtest("Overlay connectivity between nodes"):
        client1.succeed("ping -c 1 ${serverNetCfg.overlay.address}")
        client1.succeed("ping -c 1 ${client2NetCfg.overlay.address}")
        server.succeed("ping -c 1 ${client2NetCfg.overlay.address}")

      with subtest("DNS readiness"):
        server.wait_for_unit("unbound.service")
        server.wait_for_open_port(${toString nodes.server.custom.services.recursive-nameserver.port}, "${serverNetCfg.overlay.address}")

      with subtest("DNS resolution of FQDNs"):
        client1.wait_until_succeeds("getent ahostsv4 ${serverNetCfg.overlay.fqdn} | grep -q '${serverNetCfg.overlay.address}'", timeout=30)
        client1.wait_until_succeeds("getent ahostsv4 ${client2NetCfg.overlay.fqdn} | grep -q '${client2NetCfg.overlay.address}'", timeout=30)
        server.wait_until_succeeds("getent ahostsv4 ${client2NetCfg.overlay.fqdn} | grep -q '${client2NetCfg.overlay.address}'", timeout=30)

      with subtest("DNS resolution of unqualified hostnames"):
        client1.wait_until_succeeds("getent ahostsv4 server | grep -q '${serverNetCfg.overlay.address}'", timeout=30)
        client1.wait_until_succeeds("getent ahostsv4 client2 | grep -q '${client2NetCfg.overlay.address}'", timeout=30)
        server.wait_until_succeeds("getent ahostsv4 client2 | grep -q '${client2NetCfg.overlay.address}'", timeout=30)

      with subtest("SSH readiness"):
        server.wait_for_unit("sshd.service")
        client2.wait_for_unit("sshd.service")
        server.wait_for_open_port(22, "${serverNetCfg.overlay.address}")
        client2.wait_for_open_port(22, "${client2NetCfg.overlay.address}")
        client1.wait_until_succeeds("timeout 5 nc -z ${serverNetCfg.overlay.address} 22", timeout=30)
        client1.wait_until_succeeds("timeout 5 nc -z ${client2NetCfg.overlay.address} 22", timeout=30)

      with subtest("SSH access restricted by role"):
        client1.succeed("${ssh} seb@server 'echo Hello'")
        client1.succeed("${ssh} seb@client2 'echo Hello'")
        server.fail("${ssh} seb@client2 'echo Hello'")

      with subtest("SSH not reachable on underlay"):
        client1.fail("${ssh} seb@${serverNetCfg.underlay.address} 'echo Hello'")
    '';
}
