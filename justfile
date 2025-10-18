set quiet := true

list:
    just --list --unsorted

update:
    nix flake update --commit-lock-file

fmt:
    nix fmt

check:
    nix flake check --no-build

repair:
    nix-store --verify --check-contents --repair

repl host='$(hostname)':
    nix repl .#nixosConfigurations.{{ host }}

[group('rebuild')]
rebuild mode='switch':
    nh os {{ mode }} .

[group('rebuild')]
switch:
    rebuild switch

[group('rebuild')]
test:
    just rebuild test

[group('rebuild')]
boot:
    just rebuild boot

[group('rebuild')]
reboot:
    just boot && reboot

[group('remote')]
deploy +hosts:
    deploy --skip-checks --targets $(echo {{ hosts }} | sed 's/[^ ]*/\.#&/g')

[group('remote')]
install host destination='root@installer':
    nix run .#install-anywhere -- {{ host }} {{ destination }}

[group('sops')]
sops-edit path:
    just _sops-do "sops edit {{ path }}"

[group('sops')]
sops-update path:
    just _sops-do "sops updatekeys {{ path }}"

[group('sops')]
sops-update-all:
    just _sops-do "find . -type f -name 'secrets.json' -exec sops updatekeys --yes {} \;"

[group('sops')]
sops-rotate path:
    just _sops-do "sops rotate --in-place {{ path }}"

[group('sops')]
sops-rotate-all:
    just _sops-do "find . -type f -name 'secrets.json' -exec sops rotate --in-place {} \;"

_sops-do command:
    -if command -v sops >/dev/null 2>&1; then {{ command }}; else nix develop .#sops --command bash -c "{{ command }}; exec zsh"; fi
