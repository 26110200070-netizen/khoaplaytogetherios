#import "UtilityFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import <QuartzCore/QuartzCore.h>

namespace UtilityFeatures {

    static Config g_config = {
        true,  // skipAds
        false, // skipAdsProxy
        false, // blockHttpAds
        false, // streamMode
        true,  // noSleep
        true,  // autoClaimAchievements (Tự động nhận thành tích)
        false, // autoSpamChat
        1.0f   // spamSpeed
    };

    typedef void* (*get_Mission_t)();
    static get_Mission_t p_get_Mission = nullptr;

    typedef bool (*get_HasAchievementReward_t)(void* this_ptr);
    static get_HasAchievementReward_t p_get_HasAchievementReward = nullptr;

    typedef void (*ShowAchievementRewardDialog_t)(void* this_ptr);
    static ShowAchievementRewardDialog_t p_ShowAchievementRewardDialog = nullptr;

    static double s_lastAchievementCheckTime = 0.0;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_get_Mission = (get_Mission_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Mission);
        p_get_HasAchievementReward = (get_HasAchievementReward_t)Memory::GetRealOffset(Offsets::Achievements::MissionSystem_get_HasAchievementReward);
        p_ShowAchievementRewardDialog = (ShowAchievementRewardDialog_t)Memory::GetRealOffset(Offsets::Achievements::MissionSystem_ShowAchievementRewardDialog);

        LOG_INFO("UtilityFeatures initialized with Auto Achievements support.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }

    void Update() {
        if (!g_config.autoClaimAchievements) return;

        double now = CACurrentMediaTime();
        if (now - s_lastAchievementCheckTime < 1.5) return; // Check every 1.5s
        s_lastAchievementCheckTime = now;

        @try {
            if (!p_get_Mission) p_get_Mission = (get_Mission_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Mission);
            if (!p_get_HasAchievementReward) p_get_HasAchievementReward = (get_HasAchievementReward_t)Memory::GetRealOffset(Offsets::Achievements::MissionSystem_get_HasAchievementReward);
            if (!p_ShowAchievementRewardDialog) p_ShowAchievementRewardDialog = (ShowAchievementRewardDialog_t)Memory::GetRealOffset(Offsets::Achievements::MissionSystem_ShowAchievementRewardDialog);

            if (p_get_Mission && p_get_HasAchievementReward && p_ShowAchievementRewardDialog) {
                void* missionSys = p_get_Mission();
                if (missionSys && (uintptr_t)missionSys >= 0x100000000ULL) {
                    if (p_get_HasAchievementReward(missionSys)) {
                        p_ShowAchievementRewardDialog(missionSys);
                    }
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }
}
