set quiet := true

rebuild := "sudo -v && nh os"

default:
    just --list --unsorted

switch:
    {{ rebuild }} switch .

test:
    {{ rebuild }} test .

boot:
    {{ rebuild }} boot .

reboot: boot
    reboot

update:
    nix flake update

fmt:
    nix fmt

check:
    nix flake check

build-iso:
    nix build .#nixosConfigurations.installer.config.formats.iso -o result
