{
    config,
    lib,
    ...
}: {
    options.myConfig.auto-cpufreq.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.auto-cpufreq.enable {
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
