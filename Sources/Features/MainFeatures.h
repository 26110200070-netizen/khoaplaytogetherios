#pragma once
#include <cstdint>

namespace MainFeatures {

    struct Config {
        bool autoPreserveFish;     // Tự động bảo quản cá
        float autoPreserveDelay;   // Delay mặc định ~0.3s
        bool autoCloseGift;        // Đóng quà (DialogRewardPopup)
        bool autoCloseCardBox;     // Đóng hộp thẻ / Gacha box (DialogResultGetItemView)
        float autoCloseDelay;      // Delay đóng quà ~0.3s
    };

    struct Stats {
        uint32_t fishPreservedCount;
        uint32_t giftsClosedCount;
        uint32_t cardBoxesClosedCount;
    };

    void Initialize();
    void EnsureHooksInstalled();
    void Update();
    Config& GetConfig();
    Stats GetStats();
    void ResetStats();

    // Active dialog tracking
    void* GetActiveFishingGetItemDialog();
    void* GetActiveRewardPopup();
    void* GetActiveResultItemView();
}
