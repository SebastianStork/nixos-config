{ inputs, self, ... }:
{
  perSystem =
    { system, lib, ... }:
    {
      packages.iso =
        (inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit (self) allHosts;
          };

          modules = lib.singleton (
            {
              config,
              inputs,
              pkgs,
              allHosts,
              ...
            }:
            {
              nixpkgs.hostPlatform = system;

              nix.settings.experimental-features = [ "pipe-operators" ];

              networking = {
                hostName = "installer";
                wireless.enable = false;
                networkmanager.enable = true;
              };

              console.keyMap = "de-latin1-nodeadkeys";

              boot.supportedFilesystems = {
                zfs = false;
                bcachefs = true;
              };

              environment.systemPackages = [ inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.default ];

              services.openssh = {
                enable = true;
                settings = {
                  PasswordAuthentication = false;
                  KbdInteractiveAuthentication = false;
                };
              };

              users.users.root.openssh.authorizedKeys.keyFiles =
                allHosts
                |> lib.attrValues
                |> lib.filter (host: host.config.networking.hostName != config.networking.hostName)
                |> lib.filter (host: host.config |> lib.hasAttr "home-manager")
                |> lib.map (host: host.config.home-manager.users.seb.custom.programs.ssh)
                |> lib.filter (ssh: ssh.enable)
                |> lib.map (ssh: ssh.publicKeyFile);
            }
          );
        }).config.system.build.images.iso-installer;
    };
}
