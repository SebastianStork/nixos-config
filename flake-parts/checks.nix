{
  inputs,
  self,
  lib,
  ...
}:
{
  perSystem =
    { self', pkgs, ... }:
    {
      checks = {
        formatting = (inputs.treefmt.lib.evalModule pkgs "${self}/treefmt.nix").config.build.check self;

        statix = pkgs.runCommand "statix" { buildInputs = [ pkgs.statix ]; } ''
          statix check ${self}
          touch $out
        '';

        deadnix = pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${self}
          touch $out
        '';

        nebula-certs =
          let
            nebulaHostsJson =
              self.allHosts
              |> lib.attrValues
              |> lib.filter (host: host.config.custom.services.nebula.enable)
              |> lib.map self.lib.nebulaHostInventory
              |> lib.toJSON
              |> pkgs.writeText "nebula-hosts.json";
          in
          pkgs.runCommandLocal "nebula-certs" { } ''
            ${lib.getExe self'.packages.nebula-check-certs} ${nebulaHostsJson}
            touch $out
          '';
      };
    };
}
