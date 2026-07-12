{
  self',
  lib,
  writeShellApplication,
  bitwarden-cli,
  ...
}:
writeShellApplication {
  name = "nebula-recert-host";

  runtimeInputs = [
    bitwarden-cli
    self'.packages.nebula-recert
  ];

  text = ''
    inventory_nix=${./inventory.nix}
  ''
  + lib.readFile ./script.sh;
}
