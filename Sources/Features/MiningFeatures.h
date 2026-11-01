#pragma once
#include <cstdint>

namespace MiningFeatures {

    struct Config {
        bool autoMineRocks;            // Tự động đập đá (Tự động tele đến đá rồi đập)
        bool autoChangeMap;            // Tự động đổi map khi hết đá
        bool cycleMapPlaza;            // Map Quảng Trường (1001)
        bool cycleMapCamping;          // Map Cắm Trại (1201)
        bool cycleMapResort;           // Map Khu Nghỉ Dưỡng (1301)
        bool cycleMapDowntown;         // Map Downtown (1502)
        bool teleAllStones;            // Tele mọi loại đá
        bool teleSmallStones;          // Tele đá nhỏ
        bool teleMediumStones;         // Tele đá vừa
        bool teleLargeStones;          // Tele đá to
        bool autoExcavate;             // Tự động đào kho báu
        float excavateDelay;           // Delay đào
    };

    struct Stats {
        uint32_t rocksInMap;           // Số đá trong map hiện tại
        uint32_t rocksMined;           // Số đá đã đập
    };

    void Initialize();
    void EnsureHooksInstalled();
    void Update();
    Config& GetConfig();
    Stats GetStats();
    void TriggerPickaxHit();
    void TriggerExcavate();
}
