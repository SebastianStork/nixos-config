{
    config,
    lib,
    ...
}: {
    options.myConfig.ssh-client.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.ssh-client.enable {
        programs.ssh = {
            enable = true;

            matchBlocks.klue-server1 = {
                hostname = "10.5.251.175";
                user = "seb";
                identitiesOnly = true;
                identityFile = ["~/.ssh/kluebero/id_ed25519"];
            };
        };
        services.ssh-agent.enable = true;
    };
}
