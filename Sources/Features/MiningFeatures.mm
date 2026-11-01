#import "MiningFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"

namespace MiningFeatures {

    static Config g_config = {
        false, // autoMineRocks
        false, // autoChangeMapMine
        false, // autoPickupItems
        false, // autoChangeMapPickup
        false, // autoExcavate
        0.3f   // excavateDelay
    };

    static Stats g_stats = { 0, 0 };

    typedef void (*OnClickPickax_t)(void* this_ptr);
    static OnClickPickax_t p_OnClickPickax = nullptr;

    typedef void (*OnClickExcavate_t)(void* this_ptr);
    static OnClickExcavate_t p_OnClickExcavate = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnClickPickax = (OnClickPickax_t)Memory::GetRealOffset(Offsets::Extended::OnClickPickax);
        p_OnClickExcavate = (OnClickExcavate_t)Memory::GetRealOffset(Offsets::Extended::OnClickExcavate);
        LOG_INFO("MiningFeatures hooks initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    void TriggerPickaxHit() {
        void* player = FishingFeatures::GetStatus().activePlayerController;
        if (player && p_OnClickPickax) {
            p_OnClickPickax(player);
            g_stats.rocksMined++;
        }
    }

    void TriggerExcavate() {
        void* player = FishingFeatures::GetStatus().activePlayerController;
        if (player && p_OnClickExcavate) {
            p_OnClickExcavate(player);
        }
    }
}
