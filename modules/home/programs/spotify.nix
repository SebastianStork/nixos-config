{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.programs.spotify;

  pauseForFirefox = pkgs.writeShellApplication {
    name = "spotify-pause-for-firefox";
    runtimeInputs = [
      pkgs.jq
      pkgs.playerctl
      pkgs.pulseaudio
    ];
    text = ''
      state_file="''${XDG_RUNTIME_DIR:?}/spotify-paused-for-firefox"

      firefox_is_playing() {
        pactl --format=json list sink-inputs | jq --exit-status '
          any(.[];
            .corked == false
            and ((
              (.properties["application.process.binary"] // "")
              + (.properties["application.name"] // "")
            ) | test("firefox"; "i"))
          )
        ' >/dev/null
      }

      update_playback() {
        if firefox_is_playing; then
          if [[ ! -e "$state_file" \
            && "$(playerctl --player=spotify status 2>/dev/null || true)" == "Playing" \
          ]] && playerctl --player=spotify pause; then
            touch "$state_file"
          fi
        elif [[ -e "$state_file" ]]; then
          sleep 0.3
          if ! firefox_is_playing; then
            playerctl --player=spotify play || true
            rm -f "$state_file"
          fi
        fi
      }

      update_playback

      LC_ALL=C pactl subscribe | while read -r event; do
        if [[ "$event" == *"sink-input"* ]]; then
          update_playback
        fi
      done

      exit 1
    '';
  };
in
{
  options.custom.programs.spotify = {
    enable = lib.mkEnableOption "";
    pauseForFirefox = lib.mkEnableOption "" // {
      default = config.custom.programs.firefox.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.spotify ];

    systemd.user.services.spotify-pause-for-firefox = lib.mkIf cfg.pauseForFirefox {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit = {
        Description = "Pause Spotify while Firefox is playing audio";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe pauseForFirefox;
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}
