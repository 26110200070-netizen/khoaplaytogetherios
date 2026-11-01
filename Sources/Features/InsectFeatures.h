#pragma once
#include <cstdint>

namespace InsectFeatures {

    struct Config {
        bool autoCatchInsect;          // Tự động bắt bọ (Tele -> đợi 2s -> vung vợt)
        bool autoChangeMap;            // Tự động đổi map khi bắt hết bọ
        bool cycleMapPlaza;            // Map Quảng Trường (1001)
        bool cycleMapCamping;          // Map Cắm Trại (1201)
        bool cycleMapResort;           // Map Khu Nghỉ Dưỡng (1301)
        bool cycleMapDowntown;         // Map Downtown (1502)
        bool showInfoPopup;            // Hiển thị popup thông tin bọ & balo
        bool insectsNoFear;            // Côn trùng không sợ hãi / không bay mất
        bool superCatchRadius;         // Tăng bán kính bắt của vợt (30m)
    };

    struct Stats {
        uint32_t insectsInMap;         // Số con bọ trong map hiện tại
        uint32_t insectsCaught;        // Đã bắt được bao nhiêu con
        int32_t backpackCount;         // Balo hiện tại
        int32_t backpackLimit;         // Giới hạn balo
    };

    void Initialize();
    void EnsureHooksInstalled();
    void Update();
    Config& GetConfig();
    Stats GetStats();
    void TriggerNetSwing();
}
