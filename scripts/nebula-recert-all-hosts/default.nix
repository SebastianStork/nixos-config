{
  self',
  lib,
  writeShellApplication,
  bitwarden-cli,
  ...
}:
writeShellApplication {
  name = "nebula-recert-all-hosts";

  runtimeInputs = [
    bitwarden-cli
    self'.packages.nebula-recert
  ];

  text = ''
    inventory_nix=${./inventory.nix}
  ''
  + lib.readFile ./script.sh;
}
