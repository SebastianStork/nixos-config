{
  config,
  self,
  lib,
  allHosts,
  ...
}:
let
  cfg = config.custom.web-services.s3-binary-cache;
in
{
  options.custom.web-services.s3-binary-cache = {
    enable = lib.mkEnableOption "";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = lib.singleton {
        assertion = config.custom.web-services.garage.enable;
        message = self.lib.mkInvalidConfigMessage "S3-Binary-Cache on ${config.networking.hostName}" "Garage must be enabled";
      };

      sops.secrets = {
        "s3-binary-cache/key-id".owner = config.users.users.garage.name;
        "s3-binary-cache/secret-key".owner = config.users.users.garage.name;
      };

      systemd.services.garage = {
        path = [ config.services.garage.package ];
        postStart = ''
          while ! garage status >/dev/null 2>&1; do sleep 1; done

          key_id="$(cat ${config.sops.secrets."s3-binary-cache/key-id".path})"
          secret_key="$(cat ${config.sops.secrets."s3-binary-cache/secret-key".path})"
          key_name="binary-cache-key"

          if ! garage key info "$key_id" >/dev/null 2>&1; then
            garage key import "$key_id" "$secret_key" -n "$key_name" --yes
          fi

          if ! garage bucket info "${cfg.domain}" >/dev/null 2>&1; then
            garage bucket create "${cfg.domain}"
          fi

          garage bucket allow "${cfg.domain}" --read --write --key "$key_id"

          garage bucket website "${cfg.domain}" --allow
        '';
      };

      custom = {
        services.caddy.virtualHosts.${cfg.domain}.port = config.custom.web-services.garage.web.port;

        meta.sites.${cfg.domain} = {
          title = "S3 Binary Cache";
          icon = "sh:nixos";
          path = "/nix-cache-info";
        };
      };
    })

    {
      nix.settings.substituters =
        allHosts
        |> lib.attrValues
        |> lib.map (host: host.config.custom.web-services.s3-binary-cache)
        |> lib.filter (cache: cache.enable)
        |> lib.map (cache: "https://${cache.domain}?priority=30&trusted=true");
    }
  ];
}
