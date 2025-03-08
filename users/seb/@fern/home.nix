{
  imports = [ ../home.nix ];

  home.stateVersion = "24.11";

  myConfig = {
    theme = "light";
    hibernation.enable = true;
  };

  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,2880x1920@60,0x0,2"
    ",preferred,auto,1,mirror,eDP-1"
  ];
}
