_: {
  imports = [ ../home.nix ];

  home.stateVersion = "23.11";

  custom.theme = "dark";

  wayland.windowManager.hyprland.settings.monitor = [ "DP-1,2560x1440@180,0x0,1" ];
}
