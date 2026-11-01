#import "InsectFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"

namespace InsectFeatures {

    static Config g_config = {
        false, // autoCatchInsect
        false, // gatherInsects
        true,  // insectNoScared
        false, // freezeInsects
        false, // autoSellInsects
        0      // filterGrade
    };

    static Stats g_stats = { 0, 0 };

    typedef void (*OnPressInsectNet_t)(void* this_ptr, bool isPress);
    static OnPressInsectNet_t p_OnPressInsectNet = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnPressInsectNet = (OnPressInsectNet_t)Memory::GetRealOffset(Offsets::Extended::OnPressInsectNet);
        LOG_INFO("InsectFeatures hooks initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    void TriggerNetSwing() {
        void* player = FishingFeatures::GetStatus().activePlayerController;
        if (player && p_OnPressInsectNet) {
            p_OnPressInsectNet(player, true);
            p_OnPressInsectNet(player, false);
            g_stats.insectsCaught++;
        }
    }
}
