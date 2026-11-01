#pragma once
#include <cstdint>

namespace MiningFeatures {
    struct Config {
        bool autoMineRocks;
        bool autoChangeMapMine;
        bool autoPickupItems;
        bool autoChangeMapPickup;
        bool autoExcavate;
        float excavateDelay;
        bool teleAllStones;
        bool teleSmallStones;
        bool teleMediumStones;
        bool teleLargeStones;
    };

    struct Stats {
        uint32_t rocksMined;
        uint32_t itemsPicked;
    };

    void Initialize();
    void EnsureHooksInstalled();
    void Update();
    Config& GetConfig();
    Stats GetStats();
    void TriggerPickaxHit();
    void TriggerExcavate();
}
