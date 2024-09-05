{
  containers.onlyoffice.config =
    { config, ... }:
    {
      sops.secrets."onlyoffice-secret-key" = {
        owner = config.users.users.onlyoffice.name;
        inherit (config.users.users.onlyoffice) group;
      };

      nixpkgs.config.allowUnfree = true;

      services.onlyoffice = {
        enable = true;
        hostname = "onlyoffice.stork-atlas.ts.net";
        jwtSecretFile = config.sops.secrets."onlyoffice-secret-key".path;
      };

      myConfig.tailscale.serve = "8000";
    };
}
