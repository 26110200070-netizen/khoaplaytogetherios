#pragma once
#include <cstdint>

namespace FarmFeatures {
    struct Config {
        bool autoHarvest;
        bool autoHarvestSellNormal;
        bool autoHarvestSellVIP;
        bool autoBuySeeds;
        bool autoBuyTools;
        bool keepVariants;
    };

    struct Stats {
        uint32_t harvestsCompleted;
    };

    void Initialize();
    void EnsureHooksInstalled();
    Config& GetConfig();
    Stats GetStats();
    void TriggerHarvestAllVIP();
}
