{ config, lib, ... }:
{
  config = lib.mkIf config.custom.desktop.hyprland.enable {
    wayland.windowManager.hyprland.extraConfig = ''
      # Variables
      $ipc = noctalia msg
      $play-pause = $ipc media toggle
      $play-next = $ipc media next
      $play-previous = $ipc media previous
      $mute = $ipc volume-mute
      $volume-up = $ipc volume-up
      $volume-down = $ipc volume-down
      $mute-mic = $ipc mic-mute
      $brightness-up = $ipc brightness-up
      $brightness-down = $ipc brightness-down
      $screenshot-monitor = grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" - | satty --filename - --copy-command wl-copy --output-filename "$XDG_SCREENSHOTS_DIR/%Y%m%d_%H%M%S.png"
      $screenshot-region = grim -g "$(slurp)" - | satty --filename - --copy-command wl-copy --output-filename "$XDG_SCREENSHOTS_DIR/%Y%m%d_%H%M%S.png"
      $screenshot-window = grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | satty --filename - --copy-command wl-copy --output-filename "$XDG_SCREENSHOTS_DIR/%Y%m%d_%H%M%S.png"

      # Bindflags:
      # r = release
      # e = repeat
      # l = locked

      # Essentials
      bind = SUPER SHIFT, C, killactive,
      bind = SUPER SHIFT, V, togglefloating,
      bind = SUPER SHIFT, F, fullscreen, 0

      # Launch programs
      bind = SUPER, RETURN, exec, foot
      ${lib.optionalString config.custom.programs.firefox.enable "bind = SUPER, B, exec, firefox"}
      ${lib.optionalString config.custom.programs.vscode.enable "bind = SUPER, C, exec, code"}
      bind = SUPER, R, exec, $ipc panel-toggle launcher
      bind = SUPER, V, exec, $ipc panel-toggle clipboard

      # Move focus
      bind = SUPER, left, movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up, movefocus, u
      bind = SUPER, down, movefocus, d
      bind = SUPER, TAB, cyclenext,

      # Move window
      bind = SUPER SHIFT, left, movewindow, l
      bind = SUPER SHIFT, right, movewindow, r
      bind = SUPER SHIFT, up, movewindow, u
      bind = SUPER SHIFT, down, movewindow, d
      bindm = SUPER, mouse:272, movewindow

      # Resize window
      binde = SUPER CONTROL, left, resizeactive, -100 0
      binde = SUPER CONTROL, right, resizeactive, 100 0
      binde = SUPER CONTROL, up, resizeactive, 0 -100
      binde = SUPER CONTROL, down, resizeactive, 0 100
      bindm = SUPER, mouse:273, resizewindow

      # Switch workspace
      ${lib.concatMapStringsSep "\n" (n: ''
        bind = SUPER, ${lib.toString n}, focusworkspaceoncurrentmonitor, ${lib.toString n}
        bind = SUPER SHIFT, ${lib.toString n}, movetoworkspacesilent, ${lib.toString n}
      '') (lib.range 1 9)}

      # Manage session
      bindrl = SUPER CONTROL, Q, exit,
      bindrl = SUPER CONTROL, L, exec, $ipc session lock
      bindrl = SUPER CONTROL, S, exec, systemctl sleep
      bindrl = SUPER CONTROL, H, exec, systemctl hibernate
      bindrl = SUPER CONTROL, B, exec, sleep 1 && hyprctl dispatch dpms off

      # Control media
      bindl = , XF86AudioPlay, exec, $play-pause
      bindel = SHIFT, XF86AudioRaiseVolume, exec, $play-next
      bindel = SHIFT, XF86AudioLowerVolume, exec, $play-previous
      bindl = , XF86AudioMute, exec, $mute
      bindel = , XF86AudioRaiseVolume, exec, $volume-up
      bindel = , XF86AudioLowerVolume, exec, $volume-down
      bindl = SHIFT, XF86AudioMute, exec, $mute-mic

      bindl = SUPER ALT, RETURN, exec, $play-pause
      bindel = SUPER ALT, right, exec, $play-next
      bindel = SUPER ALT, left, exec, $play-previous
      bindl = SUPER ALT, BACKSPACE, exec, $mute
      bindel = SUPER ALT, up, exec, $volume-up
      bindel = SUPER ALT, down, exec, $volume-down
      bindl = SUPER ALT, M, exec, $mute-mic

      # Adjust brightness
      bindel = , XF86MonBrightnessUp, exec, $brightness-up
      bindel = , XF86MonBrightnessDown, exec, $brightness-down

      bindel = SUPER ALT, plus, exec, $brightness-up
      bindel = SUPER ALT, minus, exec, $brightness-down

      # Screenshot
      bind = , Print, exec, $screenshot-monitor
      bind = SHIFT, Print, exec, $screenshot-region
      bind = CONTROL, Print, exec, $screenshot-window

      bind = SUPER, P, exec, $screenshot-monitor
      bind = SUPER SHIFT, P, exec, $screenshot-region
      bind = SUPER CONTROL, P, exec, $screenshot-window

      # Special workspaces
      "bind = SUPER, Q, togglespecialworkspace, flake"
      ${lib.optionalString config.custom.programs.spotify.enable "bind = SUPER, S, togglespecialworkspace, music"}
      ${lib.optionalString config.custom.programs.discord.enable "bind = SUPER, D, togglespecialworkspace, chat"}
      ${lib.optionalString config.custom.programs.btop.enable "bind = SUPER, M, togglespecialworkspace, monitor"}
      ${lib.optionalString config.custom.programs.nemo.enable "bind = SUPER, F, togglespecialworkspace, files"}
      ${lib.optionalString config.custom.programs.obsidian.enable "bind = SUPER, N, togglespecialworkspace, notes"}
    '';
  };
}
