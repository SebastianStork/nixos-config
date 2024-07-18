{
  imports = [ ../default.nix ];

  home-manager.users.seb = {
    home.stateVersion = "23.11";

    myConfig = {
      theme = "light";
      sops.enable = true;
    };

    wayland.windowManager.hyprland.settings.monitor = [
      "eDP-1,1920x1080@60,0x0,1"
      ",preferred,auto,1,mirror,eDP-1"
    ];
  };
}
