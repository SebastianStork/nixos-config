{ self, lib, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    let
      nebulaHostsJson =
        self.allHosts
        |> lib.attrValues
        |> lib.filter (host: host.config.custom.networking.overlay.enable)
        |> lib.map self.lib.nebulaHostInventory
        |> lib.toJSON
        |> pkgs.writeText "nebula-hosts.json";
    in
    {
      checks = {
        nebula-cert-consistency =
          pkgs.runCommand "nebula-cert-consistency" { buildInputs = [ self'.packages.nebula-check-certs ]; }
            ''
              nebula-check-certs ${nebulaHostsJson}
              touch $out
            ''
          // {
            runsOn = [ "ci" ];
            cache = false;
          };

        nebula-cert-expiry =
          pkgs.runCommand "nebula-cert-expiry" { buildInputs = [ self'.packages.nebula-check-certs ]; } ''
            nebula-check-certs --valid-for 720h ${nebulaHostsJson}
            touch $out
          ''
          // {
            runsOn = [ "schedule" ];
            cache = false;
          };
      };
    };
}
