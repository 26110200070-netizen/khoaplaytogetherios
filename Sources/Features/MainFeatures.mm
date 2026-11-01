#import "MainFeatures.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "PlayerFeatures.h"
#import <QuartzCore/QuartzCore.h>

namespace MainFeatures {

    static Config g_config = {
        true,  // autoPreserveFish
        0.30f, // autoPreserveDelay
        true,  // autoCloseGift
        true,  // autoCloseCardBox
        0.30f, // autoCloseDelay
        true,  // autoClickOK
        false  // teleGuideArrow
    };

    static Stats g_stats = { 0, 0, 0 };

    typedef void* (*SystemHelper_get_Dialog_t)();
    static SystemHelper_get_Dialog_t p_get_Dialog = nullptr;

    typedef void* (*SystemHelper_get_Map_t)();
    static SystemHelper_get_Map_t p_get_Map = nullptr;

    typedef void* (*DialogSystem_FindTypeFirst_t)(void* this_ptr, int32_t findtype);
    static DialogSystem_FindTypeFirst_t p_FindTypeFirst = nullptr;

    typedef void (*DialogFishingGetItem_OnClick_Close_t)(void* this_ptr);
    static DialogFishingGetItem_OnClick_Close_t p_DialogFishingGetItem_OnClick_Close = nullptr;

    typedef void (*DialogRewardPopup_OnClickYes_t)(void* this_ptr);
    static DialogRewardPopup_OnClickYes_t p_DialogRewardPopup_OnClickYes = nullptr;

    typedef void (*DialogResultGetItemView_CloseFromBack_t)(void* this_ptr);
    static DialogResultGetItemView_CloseFromBack_t p_DialogResultGetItemView_CloseFromBack = nullptr;

    typedef GameTypes::Vector3 (*Transform_get_position_t)(void* transform);
    static Transform_get_position_t p_Transform_get_position = nullptr;

    static double s_lastPreserveTime = 0.0;
    static double s_lastGiftCloseTime = 0.0;
    static double s_lastCardCloseTime = 0.0;
    static double s_lastTeleGuideTime = 0.0;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_get_Dialog = (SystemHelper_get_Dialog_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Dialog);
        p_get_Map = (SystemHelper_get_Map_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Map);
        p_FindTypeFirst = (DialogSystem_FindTypeFirst_t)Memory::GetRealOffset(Offsets::SystemHelper::DialogSystem_FindTypeFirst);

        p_DialogFishingGetItem_OnClick_Close = (DialogFishingGetItem_OnClick_Close_t)Memory::GetRealOffset(Offsets::Dialogs::DialogFishingGetItem_OnClick_Close);
        p_DialogRewardPopup_OnClickYes = (DialogRewardPopup_OnClickYes_t)Memory::GetRealOffset(Offsets::Dialogs::DialogRewardPopup_OnClickYes);
        p_DialogResultGetItemView_CloseFromBack = (DialogResultGetItemView_CloseFromBack_t)Memory::GetRealOffset(Offsets::Dialogs::DialogResultGetItemView_DialogCloseFromBack);
        p_Transform_get_position = (Transform_get_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_get_position);

        LOG_INFO("MainFeatures initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }
    void ResetStats() { g_stats = { 0, 0, 0 }; }

    void TriggerTeleGuide() {
        @try {
            if (!p_get_Map) p_get_Map = (SystemHelper_get_Map_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Map);
            if (!p_Transform_get_position) p_Transform_get_position = (Transform_get_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_get_position);

            if (p_get_Map && p_Transform_get_position) {
                void* mapSys = p_get_Map();
                if (mapSys && (uintptr_t)mapSys >= 0x100000000ULL) {
                    void* guideArrow = *(void**)((uintptr_t)mapSys + 0x60);
                    if (guideArrow && (uintptr_t)guideArrow >= 0x100000000ULL) {
                        void* targetPoint = *(void**)((uintptr_t)guideArrow + 0x20);
                        if (targetPoint && (uintptr_t)targetPoint >= 0x100000000ULL) {
                            GameTypes::Vector3 tpos = p_Transform_get_position(targetPoint);
                            PlayerFeatures::Teleport(tpos.x, tpos.y + 0.3f, tpos.z);
                        }
                    }
                }
            }
        } @catch (NSException *ex) {}
    }

    void Update() {
        @try {
            if (!p_get_Dialog) p_get_Dialog = (SystemHelper_get_Dialog_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Dialog);
            if (!p_FindTypeFirst) p_FindTypeFirst = (DialogSystem_FindTypeFirst_t)Memory::GetRealOffset(Offsets::SystemHelper::DialogSystem_FindTypeFirst);
            if (!p_DialogFishingGetItem_OnClick_Close) p_DialogFishingGetItem_OnClick_Close = (DialogFishingGetItem_OnClick_Close_t)Memory::GetRealOffset(Offsets::Dialogs::DialogFishingGetItem_OnClick_Close);
            if (!p_DialogRewardPopup_OnClickYes) p_DialogRewardPopup_OnClickYes = (DialogRewardPopup_OnClickYes_t)Memory::GetRealOffset(Offsets::Dialogs::DialogRewardPopup_OnClickYes);
            if (!p_DialogResultGetItemView_CloseFromBack) p_DialogResultGetItemView_CloseFromBack = (DialogResultGetItemView_CloseFromBack_t)Memory::GetRealOffset(Offsets::Dialogs::DialogResultGetItemView_DialogCloseFromBack);

            double now = CACurrentMediaTime();

            // 1. Tele Hướng Dẫn (MapGuideArrow)
            if (g_config.teleGuideArrow && (now - s_lastTeleGuideTime >= 1.0)) {
                s_lastTeleGuideTime = now;
                TriggerTeleGuide();
            }

            if (!p_get_Dialog || !p_FindTypeFirst) return;
            void* dialogSys = p_get_Dialog();
            if (!dialogSys || (uintptr_t)dialogSys < 0x100000000ULL) return;

            // 2. Tự Động Bảo Quản & Tự Bấm OK (DialogFishingGetItem = 400)
            if ((g_config.autoPreserveFish || g_config.autoClickOK) && p_DialogFishingGetItem_OnClick_Close) {
                void* fishDialog = p_FindTypeFirst(dialogSys, 400);
                if (fishDialog && (uintptr_t)fishDialog >= 0x100000000ULL) {
                    if (now - s_lastPreserveTime >= (double)g_config.autoPreserveDelay) {
                        s_lastPreserveTime = now;
                        p_DialogFishingGetItem_OnClick_Close(fishDialog);
                        g_stats.fishPreservedCount++;
                    }
                }
            }

            // 3. Tự Động Đóng Hộp Quà & Bấm OK (DialogRewardPopup = 21)
            if ((g_config.autoCloseGift || g_config.autoClickOK) && p_DialogRewardPopup_OnClickYes) {
                void* giftDialog = p_FindTypeFirst(dialogSys, 21);
                if (giftDialog && (uintptr_t)giftDialog >= 0x100000000ULL) {
                    if (now - s_lastGiftCloseTime >= (double)g_config.autoCloseDelay) {
                        s_lastGiftCloseTime = now;
                        p_DialogRewardPopup_OnClickYes(giftDialog);
                        g_stats.giftsClosedCount++;
                    }
                }
            }

            // 4. Tự Động Đóng Hộp Thẻ / Gacha Box (DialogResultGetItemView = 96)
            if (g_config.autoCloseCardBox && p_DialogResultGetItemView_CloseFromBack) {
                void* cardDialog = p_FindTypeFirst(dialogSys, 96);
                if (cardDialog && (uintptr_t)cardDialog >= 0x100000000ULL) {
                    if (now - s_lastCardCloseTime >= (double)g_config.autoCloseDelay) {
                        s_lastCardCloseTime = now;
                        p_DialogResultGetItemView_CloseFromBack(cardDialog);
                        g_stats.cardBoxesClosedCount++;
                    }
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void* GetActiveFishingGetItemDialog() { return nullptr; }
    void* GetActiveRewardPopup() { return nullptr; }
    void* GetActiveResultItemView() { return nullptr; }
}
