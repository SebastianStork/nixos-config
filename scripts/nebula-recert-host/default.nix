{
  lib,
  writeShellApplication,
  nebula,
  bitwarden-cli,
  ...
}:
writeShellApplication {
  name = "nebula-recert-host";

  runtimeInputs = [
    nebula
    bitwarden-cli
  ];

  text = lib.readFile ./script.sh;
}
