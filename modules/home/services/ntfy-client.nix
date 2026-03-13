{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.services.ntfy-client;

  notifyScript = pkgs.writeShellApplication {
    name = "ntfy-notify";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      case "$NTFY_PRIORITY" in
        1|2)
          urgency=low
          ;;
        3)
          urgency=normal
          ;;
        4|5)
          urgency=critical
          ;;
      esac

      notify-send \
        --app-name="ntfy - $NTFY_TOPIC" \
        --urgency="$urgency" \
        "$NTFY_TITLE" \
        "$NTFY_MESSAGE"
    '';
  };
in
{
  options.custom.services.ntfy-client = {
    enable = lib.mkEnableOption "";
    topic = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "splitleaf";
    };
    server = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "https://ntfy.sh";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."ntfy/client.yml".source =
      {
        default-host = cfg.server;
        subscribe = lib.singleton {
          inherit (cfg) topic;
          command = lib.getExe notifyScript;
        };
      }
      |> (pkgs.formats.yaml { }).generate "ntfy-client.yml";

    systemd.user.services.ntfy-client = {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit = {
        Description = "ntfy client subscription";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        X-Restart-Triggers = [ config.xdg.configFile."ntfy/client.yml".source ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.ntfy-sh} subscribe --from-config";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
