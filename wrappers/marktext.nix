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
            wrappers.marktext = {
                basePackage = pkgs.marktext;
                flags = [(lib.mkIf disableGPU "--disable-gpu")];
            };
        }
    ];
})
.config
.wrappers
.marktext
.wrapped
