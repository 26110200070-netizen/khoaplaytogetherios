#pragma once
#include <cstdint>

namespace UtilityFeatures {
    struct Config {
        bool skipAds;
        bool skipAdsProxy;
        bool blockHttpAds;
        bool streamMode;
        bool noSleep;
        bool autoClaimAchievements; // Tự động nhận thành tích
        bool autoSpamChat;
        float spamSpeed;
    };

    void Initialize();
    void EnsureHooksInstalled();
    void Update();
    Config& GetConfig();
}
