{
  containers.onlyoffice.config =
    { config, lib, ... }:
    {
      sops.secrets."onlyoffice-secret-key" = {
        owner = config.users.users.onlyoffice.name;
        inherit (config.users.users.onlyoffice) group;
      };

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "corefonts" ];

      services.onlyoffice = {
        enable = true;
        hostname = "onlyoffice.stork-atlas.ts.net";
        jwtSecretFile = config.sops.secrets."onlyoffice-secret-key".path;
      };

      myConfig.tailscale.serve = "8000";
    };
}
