{
    inputs,
    pkgs,
    ...
}: {
    imports = [
        ../default.nix
        ./hardware.nix

        inputs.disko.nixosModules.default
        ./disko.nix
    ];

    networking.hostName = "seb-desktop";

    environment.sessionVariables.FLAKE = "/home/seb/Projects/nixos/my-config";

    myConfig = {
        boot-loader.systemd-boot.enable = true;

        dm.lightdm.enable = true;
        de.qtile.enable = true;

        sound.pipewire.enable = true;
        auto-gc.enable = true;
        vm.qemu.enable = true;
        flatpak.enable = true;
        vpn.lgs.enable = true;
        comma.enable = true;
        sops.enable = true;
        nix-helper.enable = true;
        printing.enable = true;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;
    services.gvfs.enable = true;
}
