{
  lib,
  writeShellApplication,
  sops,
  ssh-to-age,
  ...
}:
writeShellApplication {
  name = "install-anywhere";

  runtimeInputs = [
    sops
    ssh-to-age
  ];

  text = lib.readFile ./script.sh;
}
