set quiet := true

default:
    just --list --unsorted

switch:
    nh os switch .

test:
    nh os test .

boot:
    nh os boot .

reboot: boot
    reboot

update:
    nix flake update

fmt:
    nix fmt

check:
    nix flake check

dev shell='default':
    nix develop .#{{ shell }} --command zsh

build-iso:
    nix run nixpkgs#nixos-generators -- --format iso --flake .#installer -o result
