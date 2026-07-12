hostName: self:
let
  host = builtins.getAttr hostName self.allHosts;
  inherit (host.pkgs) lib;
in
if host.config.custom.services.nebula.enable then
  host |> self.lib.nebulaHostInventory |> lib.singleton
else
  throw "host ${hostName} does not have Nebula enabled"
