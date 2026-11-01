#import "UtilityFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"

namespace UtilityFeatures {

    static Config g_config = {
        true,  // skipAds
        false, // skipAdsProxy
        false, // blockHttpAds
        false, // streamMode
        true,  // noSleep
        false, // autoSpamChat
        1.0f   // spamSpeed
    };

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        LOG_INFO("UtilityFeatures initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
}
