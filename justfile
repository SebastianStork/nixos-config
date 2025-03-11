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
