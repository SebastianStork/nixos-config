{
  nixpkgs,
  self,
  inputs,
  ...
}:
{
  flake = {
    nixosConfigurations = {
      north = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit self inputs;
        };
        modules = [
          "${self}/hosts/north"
          "${self}/users/seb/@north"
        ];
      };
      inspiron = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit self inputs;
        };
        modules = [
          "${self}/hosts/inspiron"
          "${self}/users/seb/@inspiron"
        ];
      };
    };
  };
}
