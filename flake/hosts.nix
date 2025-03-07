{
  inputs,
  self,
  lib,
  ...
}:
let
  mkHost = hostname: {
    ${hostname} = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self; };
      modules =
        [
          { networking.hostName = hostname; }
          "${self}/hosts/${hostname}"
        ]
        ++ builtins.filter (path: builtins.pathExists path) (
          map (user: "${self}/users/${user}/@${hostname}") (
            builtins.attrNames (lib.filterAttrs (_: v: v == "directory") (builtins.readDir "${self}/users"))
          )
        );
    };
  };
in
{
  flake = {
    nixosConfigurations = lib.mkMerge [
      (mkHost "north")
      (mkHost "inspiron")
      (mkHost "fern")
      (mkHost "stratus")
      (mkHost "installer")
    ];

    deploy.nodes.stratus = {
      hostname = "stratus";
      sshUser = "root";
      remoteBuild = true;
      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.stratus;
    };
  };
}
