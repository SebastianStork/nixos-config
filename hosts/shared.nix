{
  config,
  inputs,
  self,
  lib,
  pkgs,
  ...
}:
{
  imports = [ self.nixosModules.default ];

  networking.domain = lib.mkDefault "stork-atlas.ts.net";

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

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
      };
    };

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
  ];

  nixpkgs.config.allowUnfree = true;

  _module.args.pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (config.nixpkgs) config;
  };
}
