{
    config,
    lib,
    ...
}: {
    options.myConfig.optimization.mode = lib.mkOption {
        type = lib.types.str;
        default = "";
    };

    config = lib.mkIf (config.myConfig.optimization.mode == "powersave") {
        services.auto-cpufreq = {
            enable = true;
            settings = {
                charger = {
                    governor = "powersave";
                    turbo = "never";
                    energy_performance_preference = "power";
                };
                battery = {
                    governor = "powersave";
                    turbo = "never";
                    energy_performance_preference = "power";
                };
            };
        };
    };
}
