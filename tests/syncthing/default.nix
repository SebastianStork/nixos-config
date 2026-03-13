{
  lib,
  ...
}:
{
  defaults =
    { config, ... }:
    {
      custom.services.syncthing = {
        enable = true;
        deviceId = ./keys/${config.networking.hostName}/syncthing.id |> lib.readFile |> lib.trim;
        certFile = ./keys/${config.networking.hostName}/syncthing.cert;
        keyFile = ./keys/${config.networking.hostName}/syncthing.key;
      };
    };

  nodes = {
    server = {
      custom = {
        networking = {
          overlay = {
            address = "10.254.250.1";
            isLighthouse = true;
            role = "server";
          };
          underlay = {
            cidr = "192.168.0.1/16";
            isPublic = true;
          };
        };

        services.syncthing.isServer = true;
      };
    };

    client1 = {
      custom.networking = {
        overlay = {
          address = "10.254.250.2";
          role = "client";
        };
        underlay.cidr = "192.168.0.2/16";
      };
    };

    client2 = {
      custom = {
        networking = {
          overlay = {
            address = "10.254.250.3";
            role = "client";
          };
          underlay.cidr = "192.168.0.3/16";
        };

        services.syncthing.folders = [ "Documents" ];
      };
    };
  };

  testScript =
    { nodes, ... }:
    let
      serverNetCfg = nodes.server.custom.networking.overlay;
      client1NetCfg = nodes.client1.custom.networking.overlay;
      client2NetCfg = nodes.client2.custom.networking.overlay;

      getSyncPort = hostName: nodes.${hostName}.custom.services.syncthing.syncPort |> toString;
    in
    ''
      start_all()

      server.wait_for_unit("syncthing.service")
      client1.wait_for_unit("syncthing.service")
      client2.wait_for_unit("syncthing.service")

      server.wait_for_unit("syncthing-init.service")
      client1.wait_for_unit("syncthing-init.service")
      client2.wait_for_unit("syncthing-init.service")

      server.wait_for_open_port(${getSyncPort "server"}, "${serverNetCfg.address}")
      client1.wait_for_open_port(${getSyncPort "client1"}, "${client1NetCfg.address}")
      client2.wait_for_open_port(${getSyncPort "client2"}, "${client2NetCfg.address}")

      with subtest("Three way sync of Documents"):
        server.wait_for_file("/var/lib/syncthing/Documents")
        client1.wait_for_file("/home/seb/Documents")
        client2.wait_for_file("/home/seb/Documents")

        server.succeed("sudo --user=syncthing touch /var/lib/syncthing/Documents/server")
        client1.succeed("sudo --user=seb touch /home/seb/Documents/client1")
        client2.succeed("sudo --user=seb touch /home/seb/Documents/client2")

        server.wait_for_file("/var/lib/syncthing/Documents/client1")
        server.wait_for_file("/var/lib/syncthing/Documents/client2")
        client1.wait_for_file("/home/seb/Documents/server")
        client1.wait_for_file("/home/seb/Documents/client2")
        client2.wait_for_file("/home/seb/Documents/server")
        client2.wait_for_file("/home/seb/Documents/client1")

      with subtest("Two way sync of Pictures"):
        server.wait_for_file("/var/lib/syncthing/Pictures")
        client1.wait_for_file("/home/seb/Pictures")
        client2.fail("test -d /home/seb/Pictures")
    '';
}
