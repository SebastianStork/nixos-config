{
    inputs,
    pkgs,
    lib,
    ...
}: {disableGPU ? false}:
(inputs.wrapper-manager.lib {
    inherit pkgs;
    modules = [
        {
            wrappers.spotify = {
                basePackage = pkgs.spotify;
                flags = [(lib.mkIf disableGPU "--disable-gpu")];
            };
        }
    ];
})
.config
.wrappers
.spotify
.wrapped
