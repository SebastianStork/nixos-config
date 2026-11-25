{ self, lib, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    {
      checks = {
        sops-recipient-consistency =
          let
            hostSopsConfigs = self.allHosts |> lib.attrValues |> lib.map (host: host.config.custom.sops);

            userSopsConfigs =
              self.allHosts
              |> lib.attrValues
              |> lib.filter (host: host.config |> lib.hasAttr "home-manager")
              |> lib.map (host: host.config.home-manager.users.seb.custom.sops);

            enabledSopsConfigs = hostSopsConfigs ++ userSopsConfigs |> lib.filter (sops: sops.enable);

            sopsRecipientMismatches =
              enabledSopsConfigs
              |> lib.concatMap (
                sopsConfig:
                let
                  secrets = sopsConfig.secretsFile |> lib.readFile |> lib.strings.fromJSON;
                  sopsMetadata = secrets.sops;

                  expectedRecipients = [
                    self.lib.adminAgePublicKey
                    sopsConfig.agePublicKey
                  ];

                  actualRecipients = (sopsMetadata.age or [ ]) |> lib.map (recipient: recipient.recipient);

                  recipientsMatch =
                    lib.sort lib.lessThan actualRecipients == lib.sort lib.lessThan expectedRecipients;
                in
                lib.optional (!recipientsMatch) (self.lib.relativePath sopsConfig.secretsFile)
              );
          in
          pkgs.runCommand "sops-recipient-consistency"
            { mismatchedPaths = sopsRecipientMismatches |> lib.concatMapStringsSep "\n" (path: "- ${path}"); }
            ''
              if [[ -n "$mismatchedPaths" ]]; then
                printf 'SOPS age recipients do not match the generated rules:\n%s\n' "$mismatchedPaths" >&2
                exit 1
              fi
              touch "$out"
            ''
          // {
            runsOn = [ "ci" ];
            cache = false;
          };
      }
      // (
        let
          nebulaHostsJson =
            self.allHosts
            |> lib.attrValues
            |> lib.filter (host: host.config.custom.networking.overlay.enable)
            |> lib.map self.lib.nebulaHostInventory
            |> lib.toJSON
            |> pkgs.writeText "nebula-hosts.json";
        in
        {
          nebula-cert-consistency =
            pkgs.runCommand "nebula-cert-consistency" { buildInputs = [ self'.packages.nebula-check-certs ]; }
              ''
                nebula-check-certs ${nebulaHostsJson}
                touch $out
              ''
            // {
              runsOn = [ "ci" ];
              cache = false;
            };

          nebula-cert-expiry =
            pkgs.runCommand "nebula-cert-expiry" { buildInputs = [ self'.packages.nebula-check-certs ]; } ''
              nebula-check-certs --valid-for 720h ${nebulaHostsJson}
              touch $out
            ''
            // {
              runsOn = [ "schedule" ];
              cache = false;
            };
        }
      );
    };
}
