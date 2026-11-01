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
    };

    struct Stats {
        uint32_t rocksMined;
        uint32_t itemsPicked;
    };

    void Initialize();
    void EnsureHooksInstalled();
    Config& GetConfig();
    Stats GetStats();
    void TriggerPickaxHit();
    void TriggerExcavate();
}
