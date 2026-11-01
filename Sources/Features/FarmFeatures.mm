#import "FarmFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import <QuartzCore/QuartzCore.h>

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

    typedef void* (*get_Dialog_t)();
    static get_Dialog_t p_get_Dialog = nullptr;

    typedef void* (*FindTypeFirst_t)(void* this_ptr, int32_t findtype);
    static FindTypeFirst_t p_FindTypeFirst = nullptr;

    static double s_lastHarvestTime = 0.0;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnClick_HarvestAll = (OnClick_HarvestAll_t)Memory::GetRealOffset(Offsets::Extended::OnClick_HarvestAll);
        p_get_Dialog = (get_Dialog_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Dialog);
        p_FindTypeFirst = (FindTypeFirst_t)Memory::GetRealOffset(Offsets::SystemHelper::DialogSystem_FindTypeFirst);

        LOG_INFO("FarmFeatures runtime pointers initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    void Update() {
        if (!g_config.autoHarvest && !g_config.autoHarvestSellVIP) return;

        double now = CACurrentMediaTime();
        if (now - s_lastHarvestTime < 1.0) return;
        s_lastHarvestTime = now;

        @try {
            if (!p_OnClick_HarvestAll) p_OnClick_HarvestAll = (OnClick_HarvestAll_t)Memory::GetRealOffset(Offsets::Extended::OnClick_HarvestAll);
            if (!p_get_Dialog) p_get_Dialog = (get_Dialog_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Dialog);
            if (!p_FindTypeFirst) p_FindTypeFirst = (FindTypeFirst_t)Memory::GetRealOffset(Offsets::SystemHelper::DialogSystem_FindTypeFirst);

            if (p_get_Dialog && p_FindTypeFirst && p_OnClick_HarvestAll) {
                void* dialogSys = p_get_Dialog();
                if (dialogSys && (uintptr_t)dialogSys >= 0x100000000ULL) {
                    // DialogMyFarmHarvest = eDialogType 413 or scan active dialogs
                    void* farmDialog = p_FindTypeFirst(dialogSys, 413);
                    if (farmDialog && (uintptr_t)farmDialog >= 0x100000000ULL) {
                        p_OnClick_HarvestAll(farmDialog);
                        g_stats.harvestsCompleted++;
                    }
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void TriggerHarvestAllVIP() {
        EnsureHooksInstalled();
    }
}
