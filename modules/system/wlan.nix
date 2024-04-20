{
    config,
    lib,
    ...
}: {
    options.myConfig.wlan.enable = lib.mkEnableOption "";

    config = lib.mkIf config.myConfig.wlan.enable {
        sops.secrets."wlan.env" = {};

        networking.networkmanager = {
            enable = true;

            ensureProfiles = {
                environmentFiles = [config.sops.secrets."wlan.env".path];

                profiles = {
                    home = {
                        connection = {
                            id = "home";
                            uuid = "24b856a6-27eb-4c4f-b85c-f59ab0824965";
                            type = "wifi";
                            interface-name = "wlp2s0";
                        };
                        wifi = {
                            mode = "infrastructure";
                            ssid = "$HOME_SSID";
                        };
                        wifi-security = {
                            auth-alg = "open";
                            key-mgmt = "wpa-psk";
                            psk = "$HOME_PSK";
                        };
                        ipv4.method = "auto";
                        ipv6 = {
                            addr-gen-mode = "default";
                            method = "auto";
                        };
                    };

                    mobile = {
                        connection = {
                            id = "mobile";
                            uuid = "e3a749cf-a103-4e1e-a50c-4a4898bafcf6";
                            type = "wifi";
                            interface-name = "wlp2s0";
                        };
                        wifi = {
                            mode = "infrastructure";
                            ssid = "$MOBILE_SSID";
                        };
                        wifi-security = {
                            auth-alg = "open";
                            key-mgmt = "wpa-psk";
                            psk = "$MOBILE_PSK";
                        };
                        ipv4.method = "auto";
                        ipv6 = {
                            addr-gen-mode = "default";
                            method = "auto";
                        };
                    };

                    school = {
                        connection = {
                            id = "school";
                            uuid = "bfdf4e7f-d2c4-4ab6-b833-37ecd5199b22";
                            type = "wifi";
                            interface-name = "wlp2s0";
                        };
                        wifi = {
                            mode = "infrastructure";
                            ssid = "$SCHOOL_SSID";
                        };
                        wifi-security = {
                            auth-alg = "open";
                            key-mgmt = "wpa-eap";
                        };
                        "802-1x" = {
                            domain-suffix-match = "lgs-hu.eu";
                            eap = "ttls;";
                            identity = "$SCHOOL_ID";
                            password = "$SCHOOL_PSK";
                            phase2-auth = "pap";
                        };
                        ipv4.method = "auto";
                        ipv6 = {
                            addr-gen-mode = "default";
                            method = "auto";
                        };
                    };
                };
            };
        };
    };
}
