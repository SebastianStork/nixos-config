{
  lib,
  writeShellApplication,
  sops,
  age,
  ...
}:
writeShellApplication {
  name = "install-anywhere";

  runtimeInputs = [
    sops
    age
  ];

  text = lib.readFile ./script.sh;
}
