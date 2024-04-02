{config, ...}: {
    imports = [../common.nix];

    sops.secrets."password/seb".neededForUsers = true;

    users.users.seb = {
        isNormalUser = true;
        description = "Sebastian Stork";
        hashedPasswordFile = config.sops.secrets."password/seb".path;
        extraGroups = ["wheel" "networkmanager" "libvirtd" "video"];
    };

    home-manager.users.seb = ./home.nix;
}
