{ pkgs, ... }:
{
  imports = [ ../common-home.nix ];

  home.sessionVariables.NH_FLAKE = "~/Projects/nixos-config";

  custom = {
    sops.enable = true;

    programs = {
      shell.zsh.enable = true;
      git.enable = true;
      kitty.enable = true;
      vscode.enable = true;
      firefox.enable = true;
      libreoffice.enable = true;
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

    pkgs.corefonts
    pkgs.roboto
    pkgs.open-sans
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
  ];

  fonts.fontconfig.enable = true;
}
