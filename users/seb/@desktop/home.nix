_: {
  imports = [ ../home.nix ];

  home.stateVersion = "23.11";

  custom = {
    sops.agePublicKey = "age1p32cyzakxtcx346ej82ftln4r2aw2pcuazq3583s85nzsan4ygqsj32hjf";
    theme = "dark";
  };

  wayland.windowManager.hyprland.settings.monitor = [ "DP-1,2560x1440@144,0x0,1" ];
}
