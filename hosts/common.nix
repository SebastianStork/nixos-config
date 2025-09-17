{
  config,
  inputs,
  self,
  pkgs,
  lib,
  ...
}:
{
  imports = [ self.nixosModules.default ];

  nix =
    let
      flakeInputs = inputs |> lib.filterAttrs (_: lib.isType "flake");
    in
    {
      channel.enable = false;
      registry = flakeInputs |> lib.mapAttrs (_: flake: { inherit flake; });
      nixPath = flakeInputs |> lib.mapAttrsToList (name: _: "${name}=flake:${name}");

      settings = {
        flake-registry = "";
        nix-path = config.nix.nixPath;

        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        auto-optimise-store = true;
        warn-dirty = false;
        trusted-users = [
          "root"
          "@wheel"
        ];
        commit-lock-file-summary = "flake.lock: Update";
        allow-import-from-derivation = false;

        min-free = "100M";
        max-free = "1G";
      };
    };

  systemd.enableStrictShellChecks = true;

  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings =
      let
        de = "de_DE.UTF-8";
      in
      {
        LC_ADDRESS = de;
        LC_IDENTIFICATION = de;
        LC_MEASUREMENT = de;
        LC_MONETARY = de;
        LC_NAME = de;
        LC_NUMERIC = de;
        LC_PAPER = de;
        LC_TELEPHONE = de;
        LC_TIME = de;
      };
  };

  console.keyMap = "de-latin1-nodeadkeys";

  users.mutableUsers = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.just
    pkgs.nh
    (lib.hiPrio pkgs.uutils-coreutils-noprefix)
  ];

  nixpkgs.config.allowUnfree = true;

  _module.args.pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (config.nixpkgs) config;
  };
}
