{
    inputs,
    config,
    lib,
    ...
}: {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    options.myConfig.sops.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.sops.enable {
        sops = {
            age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
            defaultSopsFile = "${inputs.self}/users/${config.home.username}/secrets.yaml";
        };
    };
}
