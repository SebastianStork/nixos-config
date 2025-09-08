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
    nix flake check --no-build

deploy +hosts:
    deploy --skip-checks --targets $(echo {{ hosts }} | sed 's/[^ ]*/\.#&/g')

install host destination='root@installer':
    nix run .#install-anywhere -- {{ host }} {{ destination }}

repair:
    nix-store --verify --check-contents --repair

repl host='$(hostname)':
    nix repl .#nixosConfigurations.{{ host }}

_sops-do command:
    -if command -v sops >/dev/null 2>&1; then {{ command }}; else nix develop .#sops --command bash -c "{{ command }}; exec zsh"; fi

sops-edit path:
    just _sops-do "sops edit {{ path }}"

sops-update:
    just _sops-do "find . -type f -name 'secrets.json' -exec sops updatekeys --yes {} \;"

sops-rotate:
    just _sops-do "find . -type f -name 'secrets.json' -exec sops rotate --in-place {} \;"
