{
  imports = [ ../home.nix ];

  home.stateVersion = "23.11";
  myConfig.de.theme = "light";

  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,1920x1080@60,0x0,1"
    ",preferred,auto,1,mirror,eDP-1"
  ];
}
