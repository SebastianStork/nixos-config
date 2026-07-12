self:
let
  inherit (self.inputs.nixpkgs) lib;
in
self.allHosts
|> lib.attrValues
|> lib.filter (host: host.config.custom.services.nebula.enable)
|> lib.map self.lib.nebulaHostInventory
