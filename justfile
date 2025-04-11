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

install host:
    ssh -o StrictHostKeyChecking=no root@installer 'disko --mode destroy,format,mount --yes-wipe-all-disks --flake github:SebastianStork/nixos-config/61083d4359d379981d4bd838998820199c5d8bb9#{{ host }} && mkdir -p /mnt/etc/ssh'
    scp -o StrictHostKeyChecking=no ~/.ssh/{{ host }} root@installer:/mnt/etc/ssh/ssh_host_ed25519_key
    scp -o StrictHostKeyChecking=no ~/.ssh/{{ host }}.pub root@installer:/mnt/etc/ssh/ssh_host_ed25519_key.pub
    ssh -o StrictHostKeyChecking=no root@installer 'nixos-install --flake github:SebastianStork/nixos-config/61083d4359d379981d4bd838998820199c5d8bb9#{{ host }} && reboot'
