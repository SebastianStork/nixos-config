{
  self',
  lib,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "nebula-recert-host";

  runtimeInputs = [
    self'.packages.nebula-recert
  ];

  text = ''
    inventory_nix=${./inventory.nix}
  ''
  + lib.readFile ./script.sh;
}
