#pragma once
#include <cstdint>

namespace MainFeatures {

    struct Config {
        bool autoPreserveFish;     // Tự động bảo quản cá
        float autoPreserveDelay;   // Delay mặc định ~0.3s
        bool autoCloseGift;        // Đóng quà (DialogRewardPopup)
        bool autoCloseCardBox;     // Đóng hộp thẻ / Gacha box (DialogResultGetItemView)
        float autoCloseDelay;      // Delay đóng quà ~0.3s
        bool autoClickOK;          // Tự động bấm OK khi nhận thưởng
        bool teleGuideArrow;       // Tele Hướng Dẫn (MapGuideArrow)
        bool autoRepairTools;      // Tự động sửa công cụ (Cần câu, cuốc đá, vợt bọ)
        bool autoOpenMailGift;     // Tự động mở & nhận tất cả quà thư (DialogMailBox)
    };

    struct Stats {
        uint32_t fishPreservedCount;
        uint32_t giftsClosedCount;
        uint32_t cardBoxesClosedCount;
        uint32_t toolsRepairedCount;
        uint32_t mailGiftsReceivedCount;
    };

    void Initialize();
    void EnsureHooksInstalled();
    void Update();
    Config& GetConfig();
    Stats GetStats();
    void ResetStats();
    void TriggerTeleGuide();
    void TriggerRepairNow();
    void TriggerReceiveAllMailNow();

    // Active dialog tracking
    void* GetActiveFishingGetItemDialog();
    void* GetActiveRewardPopup();
    void* GetActiveResultItemView();
}
