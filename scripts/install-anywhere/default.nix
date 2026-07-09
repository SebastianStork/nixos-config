{
  lib,
  writeShellApplication,
  sops,
  ssh-to-age,
  bitwarden-cli,
  ...
}:
writeShellApplication {
  name = "install-anywhere";

  runtimeInputs = [
    sops
    ssh-to-age
    bitwarden-cli
  ];

  text = lib.readFile ./script.sh;
}
