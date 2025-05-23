set quiet := true

default:
    just --list --unsorted

rebuild mode='switch':
    nh os {{ if mode == 'reboot' { 'boot' } else { mode } }} .
    {{ if mode == 'reboot' { 'reboot' } else { '' } }}

update:
    nix flake update --commit-lock-file

fmt:
    nix fmt

check:
    nix flake check

dev shell='default':
    nix develop .#{{ shell }} --command zsh

deploy +hosts:
    deploy --skip-checks --targets $(echo {{ hosts }} | sed 's/[^ ]*/\.#&/g')

install host destination='root@installer':
    nix run github:nix-community/nixos-anywhere -- --extra-files ~/.ssh/{{ host }} --flake .#{{ host }} --target-host {{ destination }}

repair:
    nix-store --verify --check-contents --repair
