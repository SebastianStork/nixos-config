{
  inputs,
  self,
  lib,
  ...
}:
let
  unstable = inputs.nixpkgs;
  stable = inputs.nixpkgs-stable;

  mkHost = hostname: nixpkgs: {
    ${hostname} = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs self;
      };
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
  flake.nixosConfigurations = lib.mkMerge [
    (mkHost "north" unstable)
    (mkHost "inspiron" unstable)
    (mkHost "installer" stable)
  ];
}
