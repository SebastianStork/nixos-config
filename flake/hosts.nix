{ inputs, self, ... }:
let
  specialArgs = {
    inherit inputs self;
  };
  modulesOf = hostname: [
    { networking.hostName = hostname; }
    "${self}/hosts/${hostname}"
    "${self}/users/seb/@${hostname}"
  ];
in
{
  flake.nixosConfigurations = {
    north = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = modulesOf "north";
    };
    inspiron = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = modulesOf "inspiron";
    };
  };
}
