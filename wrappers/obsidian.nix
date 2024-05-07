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
            wrappers.obsidian = {
                basePackage = pkgs.obsidian;
                flags = [(lib.mkIf disableGPU "--disable-gpu")];
            };
        }
    ];
})
.config
.wrappers
.obsidian
.wrapped
