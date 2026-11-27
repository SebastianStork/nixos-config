{
  config,
  lib,
  self,
  allHosts,
  ...
}:
let
  cfg = config.custom.services.nh-deployment;
  user = "deploy";
in
{
  options.custom.services.nh-deployment.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    assertions = lib.singleton {
      assertion = config.custom.services.sshd.enable;
      message = self.lib.mkInvalidConfigMessage "nh deployment" "the SSH service must be enabled";
    };

    custom.services.sshd.additionalAllowedUsers = [ user ];

    services.openssh.extraConfig = lib.mkAfter ''
      Match User ${user}
        DisableForwarding yes
        PermitTTY no
    '';

    users = {
      users.${user} = {
        isSystemUser = true;
        group = user;
        useDefaultShell = true;
        openssh.authorizedKeys.keyFiles =
          allHosts
          |> lib.attrValues
          |> lib.filter (host: host.config |> lib.hasAttr "home-manager")
          |> lib.map (host: host.config.home-manager.users.seb.custom.programs.ssh.deploy)
          |> lib.filter (deploy: deploy.enable)
          |> lib.map (deploy: deploy.publicKeyFile);
      };
      groups.${user} = { };
    };

    nix.settings.allowed-users = [ user ];

    security.sudo.extraRules =
      let
        systemClosure = "/nix/store/*-nixos-system-${config.networking.hostName}-*";
      in
      lib.singleton {
        users = [ user ];
        runAs = "root";
        commands = [
          {
            command = "/run/current-system/sw/bin/nix build --no-link --profile /nix/var/nix/profiles/system ${systemClosure}";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${systemClosure}/bin/switch-to-configuration switch";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${systemClosure}/bin/switch-to-configuration boot";
            options = [ "NOPASSWD" ];
          }
        ];
      };
  };
}
