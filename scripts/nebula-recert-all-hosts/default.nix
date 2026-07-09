{
  self',
  lib,
  writeShellApplication,
  bitwarden-cli,
  jq,
  ...
}:
writeShellApplication {
  name = "nebula-recert-all-hosts";

  runtimeInputs = [
    bitwarden-cli
    jq
    self'.packages.nebula-recert-host
  ];

  text = lib.readFile ./script.sh;
}
