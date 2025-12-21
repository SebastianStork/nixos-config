_: {
  imports = [ ../home.nix ];

  home.stateVersion = "24.11";

  custom = {
    sops.agePublicKey = "age190mf9wx4ct7qvne3ly9j3cj9740z5wnfhsl6vsc5wtfyc5pueuas9hnjtr";
    theme = "light";
    programs.brightnessctl.enable = true;
  };

  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,2880x1920@120,0x0,2,vrr,2"
    ",preferred,auto,1,mirror,eDP-1"
  ];
}
