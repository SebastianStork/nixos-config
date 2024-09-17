{ lib, ... }:
{
  imports = lib.mapAttrsToList (name: _: ./${name}) (
    lib.filterAttrs (_: value: value == "directory") (builtins.readDir ./.)
  );

  virtualisation.oci-containers.backend = "docker";
}
