#pragma once
#include <cstdint>

namespace UtilityFeatures {
    struct Config {
        bool skipAds;
        bool skipAdsProxy;
        bool blockHttpAds;
        bool streamMode;
        bool noSleep;
        bool autoSpamChat;
        float spamSpeed;
    };

    void Initialize();
    void EnsureHooksInstalled();
    Config& GetConfig();
}
