# Copilot Instructions — nixos-config

## Architecture

This is a **NixOS flake** managing multiple hosts using [flake-parts](https://flake.parts). The flake output is composed entirely from `flake-parts/*.nix` — each file is auto-imported via `builtins.readDir`.

### Layers (top → bottom)

1. **Hosts** (`hosts/`) — minimal per-machine config: profile import, overlay IP, underlay interface, enabled services. All `.nix` files in a host directory are auto-imported recursively by `flake-parts/hosts.nix`.
   - **External hosts** (`external-hosts/`) — non-NixOS devices (e.g., a phone) that participate in the overlay network and syncthing cluster but aren't managed by NixOS. They import `nixosModules.default` directly (no profile) and only declare `custom.networking` and `custom.services` options so their config values are discoverable by other hosts. This enables auto-generating nebula certs, DNS records, and syncthing device lists for them.
   - `allHosts` = `nixosConfigurations // externalConfigurations` — passed to every module via `specialArgs`, so any module can query the full fleet including external devices.
2. **Profiles** (`profiles/`) — role presets. `core.nix` is the base for all hosts; `server.nix` and `workstation.nix` extend it. Profile names become `nixosModules.<name>-profile`.
3. **Modules** (`modules/system/`, `modules/home/`) — reusable NixOS/Home Manager modules auto-imported as `nixosModules.default` / `homeModules.default`. Every module is always imported; activation is gated by `lib.mkEnableOption` + `lib.mkIf`.
4. **Users** (`users/seb/`) — Home Manager config. Per-host overrides live in `@<hostname>/` subdirectories (e.g., `users/seb/@desktop/home.nix` imports `../home.nix` and adds host-specific settings).

### Networking model

- **Underlay** (`modules/system/networking/underlay.nix`) — physical network via systemd-networkd.
- **Overlay** (`modules/system/networking/overlay.nix`, `modules/system/services/nebula/`) — Nebula mesh VPN (`10.254.250.0/24`, domain `splitleaf.de`). All inter-host communication (DNS, Caddy, SSH) routes over the overlay.
- **DNS** (`modules/system/services/dns.nix`) — Unbound on overlay, auto-generates records from `allHosts`.

### Web services pattern

Each web service module (`modules/system/web-services/*.nix`) follows a consistent structure:

```nix
options.custom.web-services.<name> = { enable; domain; port; doBackups; };
config = lib.mkIf cfg.enable {
  # upstream NixOS service config
  custom.services.caddy.virtualHosts.${cfg.domain}.port = cfg.port;  # reverse proxy
  custom.services.restic.backups.<name> = lib.mkIf cfg.doBackups { ... };  # backup
  custom.persistence.directories = [ ... ];  # impermanence
};
```

Hosts enable services declaratively: `custom.web-services.forgejo = { enable = true; domain = "git.example.com"; doBackups = true; };`

## Conventions

- **All custom options** live under `custom.*` — never pollute the top-level NixOS namespace.
- **`cfg` binding**: always `let cfg = config.custom.<path>;` at module top.
- **Pipe operator** (`|>`): used pervasively instead of nested function calls.
- **No repeated attrpaths** (per `statix`): group assignments into a single attrset instead of repeating the path. E.g. `custom.networking.overlay = { address = "..."; role = "server"; };` — not `custom.networking.overlay.address = "..."; custom.networking.overlay.role = "server";`. Setting a single attribute with the full path is fine. Conversely, don't nest single-key attrsets unnecessarily — use `custom.networking.overlay.address = "...";` not `custom = { networking = { overlay = { address = "..."; }; }; };`.
- **`lib.singleton`** instead of `[ x ]` for single-element lists.
- **`lib.mkEnableOption ""`**: empty string is intentional — descriptions come from the option path.
- **Secrets**: [sops-nix](https://github.com/Mic92/sops-nix) with age keys. Each host/user has `secrets.json` + `keys/age.pub`. The `.sops.yaml` at repo root is a placeholder — the real config is generated via `nix build .#sops-config` (see `flake-parts/sops-config.nix`).
- **Impermanence**: servers use `custom.persistence.enable = true` with an explicit `/persist` mount. Modules add their state directories via `custom.persistence.directories`.
- **Formatting**: `nix fmt` runs `nixfmt` + `prettier` + `just --fmt` via treefmt.
- **Path references**: use `./` for files in the same directory or a subdirectory. Use `${self}/...` when the path would require going up a directory (`../`). Never use `../`.
- **Cross-host data**: modules receive `allHosts` via `specialArgs` (see Hosts layer above). Used by DNS, nebula static host maps, syncthing device lists, and caddy service records.

## Developer Workflows

| Task | Command |
|---|---|
| Rebuild & switch locally | `just switch` |
| Test config without switching | `just test` |
| Deploy to remote host(s) | `just deploy hostname1 hostname2` |
| Format all files | `just fmt` or `nix fmt` |
| Run flake checks + tests | `just check` |
| Check without building | `just check-lite` |
| Update flake inputs | `just update` |
| Edit SOPS secrets | `just sops-edit hosts/<host>/secrets.json` |
| Rotate all secrets | `just sops-rotate-all` |
| Install a new host | `just install <host> root@<ip>` |
| Open nix repl for a host | `just repl <hostname>` |

SOPS commands auto-enter a `nix develop .#sops` shell if `sops` isn't available, which handles Bitwarden login and age key retrieval.

## Adding a New Module

1. Create `modules/system/services/<name>.nix` (or `web-services/`, `programs/`, etc.).
2. Define options under `options.custom.<category>.<name>` with `lib.mkEnableOption ""`.
3. Guard all config with `lib.mkIf cfg.enable { ... }`.
4. For web services: set `custom.services.caddy.virtualHosts`, optionally `custom.services.restic.backups`, and `custom.persistence.directories`.
5. No imports needed — the file is auto-discovered by `flake-parts/modules.nix`.

## Adding a New Host

1. Create `hosts/<hostname>/` with `default.nix`, `disko.nix`, `hardware.nix`, `secrets.json`, and `keys/` (containing `age.pub`, `nebula.pub`).
2. In `default.nix`, import the appropriate profile (`self.nixosModules.server-profile` or `self.nixosModules.workstation-profile`) and set `custom.networking.overlay.address` + `custom.networking.underlay.*`.
3. The host is auto-discovered by `flake-parts/hosts.nix` — no registration needed.

## Tests

Integration tests live in `tests/` and use NixOS VM testing (`pkgs.testers.runNixOSTest`). Run via `just check`. Key details:

- Each test directory contains a `default.nix` that returns a test attrset (with `defaults`, `nodes`, `testScript`, etc.).
- The `defaults` block imports `self.nixosModules.default` and **overrides `allHosts`** with the test's own `nodes` variable: `_module.args.allHosts = nodes |> lib.mapAttrs (_: node: { config = node; });`. This scopes cross-host lookups (DNS records, nebula static maps, etc.) to only the test's VMs, preventing evaluation of real host configs.
- Test nodes define their own overlay addresses, underlay interfaces, and use pre-generated nebula keys from `tests/*/keys/`.
- The `testScript` is written in Python, using helpers like `wait_for_unit`, `succeed`, and `fail` to assert behavior.
