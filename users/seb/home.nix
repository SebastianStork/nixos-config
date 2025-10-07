{ pkgs, ... }:
{
  imports = [ ../common-home.nix ];

  home.sessionVariables.NH_FLAKE = "~/Projects/nixos-config";

  custom = {
    sops.enable = true;

    programs = {
      shell.zsh.enable = true;
      kitty.enable = true;
      firefox.enable = true;
      git.enable = true;
      vscode.enable = true;
    };
  };

  home.packages = [
    pkgs.bottom
    pkgs.fastfetch

    pkgs.nemo-with-extensions
    pkgs.celluloid
    pkgs.spotify
    pkgs.obsidian
    pkgs.anki
    pkgs.discord

    pkgs.libreoffice
    pkgs.hunspell
    pkgs.hunspellDicts.de_DE
    pkgs.hunspellDicts.en_US

    pkgs.corefonts
    pkgs.roboto
    pkgs.open-sans
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
  ];

  fonts.fontconfig.enable = true;

  home.file."Projects/.stignore".text = ''
    (?d)target/
    (?d).direnv/
    (?d)result
  '';
}
