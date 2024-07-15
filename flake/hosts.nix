{
  self,
  inputs,
  lib,
  ...
}:
let
  subdirsOf =
    dir: builtins.attrNames (lib.filterAttrs (_: v: v == "directory") (builtins.readDir dir));
in
{
  flake.nixosConfigurations = lib.genAttrs (subdirsOf "${self}/hosts") (
    name:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit self inputs;
      };
      modules = [
        "${self}/hosts/${name}"
        "${self}/users/seb/@${name}"
        { networking.hostName = name; }
      ];
    }
  );
}