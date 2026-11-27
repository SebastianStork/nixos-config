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
                wireless.enable = lib.mkForce false;
                networkmanager.enable = true;
              };

              console.keyMap = "de-latin1-nodeadkeys";

              boot = {
                bcachefs.modulePackage = config.boot.kernelPackages.bcachefs.overrideAttrs (oldAttrs: {
                  postPatch = (oldAttrs.postPatch or "") + ''
                    substituteInPlace src/fs/bcachefs/vfs/fs.h \
                      --replace-fail \
                        'KERNEL_VERSION(6,19,0)' \
                        'KERNEL_VERSION(6,18,64)'
                  '';
                });

                supportedFilesystems = {
                  zfs = false;
                  bcachefs = true;
                };
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
                |> lib.map (host: host.config.home-manager.users.seb.custom.programs.ssh.login)
                |> lib.filter (login: login.enable)
                |> lib.map (login: login.publicKeyFile);
            }
          );
        }).config.system.build.images.iso-installer;
    };
}
