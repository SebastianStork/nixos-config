_: {
  imports = [ ../home.nix ];

  home.stateVersion = "24.11";

  custom = {
    theme = "light";
    programs.brightnessctl.enable = true;
  };

  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,2880x1920@120,0x0,2,vrr,2"
    ",preferred,auto,1,mirror,eDP-1"
  ];
}
