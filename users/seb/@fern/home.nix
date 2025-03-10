{
  imports = [ ../home.nix ];

  home.stateVersion = "24.11";

  myConfig.theme = "light";

  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,2880x1920@120,0x0,2,vrr,1"
    ",preferred,auto,1,mirror,eDP-1"
  ];
}
