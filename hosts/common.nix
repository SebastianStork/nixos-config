{ self, pkgs, ... }:
{
  imports = [
    self.nixosModules.default
    self.wrappers.default
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    warn-dirty = false;
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings =
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

  console.keyMap = "de-latin1-nodeadkeys";

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
  users.defaultUserShell = pkgs.zsh;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = [ pkgs.git ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
      "corefonts"
      "nvidia-x11"
      "nvidia-settings"
      "spotify"
      "obsidian"
      "davinci-resolve"
    ];

  users.mutableUsers = false;
}
