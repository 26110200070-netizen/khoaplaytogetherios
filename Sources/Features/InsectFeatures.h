#pragma once
#include <cstdint>

namespace InsectFeatures {
    struct Config {
        bool autoCatchInsect;
        bool gatherInsects;
        bool insectNoScared;
        bool freezeInsects;
        bool autoSellInsects;
        int filterGrade; // 0: Tất cả, 1: Xanh lá, 2: Xanh dương, 3: Tím
    };

    struct Stats {
        uint32_t insectsCaught;
        uint32_t insectsSold;
    };

    void Initialize();
    void EnsureHooksInstalled();
    Config& GetConfig();
    Stats GetStats();
    void TriggerNetSwing();
}
