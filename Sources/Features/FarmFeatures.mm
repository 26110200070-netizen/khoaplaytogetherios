#import "FarmFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"

namespace FarmFeatures {

    static Config g_config = {
        false, // autoHarvest
        false, // autoHarvestSellNormal
        false, // autoHarvestSellVIP
        false, // autoBuySeeds
        false, // autoBuyTools
        true   // keepVariants
    };

    static Stats g_stats = { 0 };

    typedef void (*OnClick_HarvestAll_t)(void* this_ptr);
    static OnClick_HarvestAll_t p_OnClick_HarvestAll = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnClick_HarvestAll = (OnClick_HarvestAll_t)Memory::GetRealOffset(Offsets::Extended::OnClick_HarvestAll);
        LOG_INFO("FarmFeatures hooks initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    void TriggerHarvestAllVIP() {
        EnsureHooksInstalled();
    }
}
