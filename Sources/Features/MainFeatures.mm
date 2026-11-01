#import "MainFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

namespace MainFeatures {

    static Config g_config = {
        true,   // autoPreserveFish
        0.3f,   // autoPreserveDelay (0.3s)
        true,   // autoCloseGift
        true,   // autoCloseCardBox
        0.3f    // autoCloseDelay (0.3s)
    };

    static Stats g_stats = { 0, 0, 0 };

    static void* g_activeFishingGetItem = nullptr;
    static void* g_activeRewardPopup = nullptr;
    static void* g_activeResultItemView = nullptr;
    static void* g_activeResultItemList = nullptr;

    typedef void* (*get_Dialog_t)();
    static get_Dialog_t p_get_Dialog = nullptr;

    typedef void* (*FindTypeFirst_t)(void* dialogSys, int findType);
    static FindTypeFirst_t p_FindTypeFirst = nullptr;

    typedef void (*DialogFishingGetItem_OnClick_Close_t)(void* this_ptr);
    static DialogFishingGetItem_OnClick_Close_t p_DialogFishingGetItem_OnClick_Close = nullptr;

    typedef void (*DialogRewardPopup_OnClickYes_t)(void* this_ptr);
    static DialogRewardPopup_OnClickYes_t p_DialogRewardPopup_OnClickYes = nullptr;

    typedef void (*DialogRewardPopup_DialogHide_t)(void* this_ptr, bool isDelete);
    static DialogRewardPopup_DialogHide_t p_DialogRewardPopup_DialogHide = nullptr;

    typedef void (*DialogResultGetItemView_CloseFromBack_t)(void* this_ptr);
    static DialogResultGetItemView_CloseFromBack_t p_DialogResultGetItemView_CloseFromBack = nullptr;

    static double s_fishDialogOpenTime = 0.0;
    static void* s_lastFishDialog = nullptr;

    static double s_rewardDialogOpenTime = 0.0;
    static void* s_lastRewardDialog = nullptr;

    static double s_resultDialogOpenTime = 0.0;
    static void* s_lastResultDialog = nullptr;

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        @try {
            if (!p_get_Dialog) {
                p_get_Dialog = (get_Dialog_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Dialog);
            }
            if (!p_get_Dialog) return;

            void* dialogSys = p_get_Dialog();
            if (!dialogSys || (uintptr_t)dialogSys < 0x100000000ULL) return;

            if (!p_FindTypeFirst) {
                p_FindTypeFirst = (FindTypeFirst_t)Memory::GetRealOffset(Offsets::SystemHelper::DialogSystem_FindTypeFirst);
            }
            if (!p_FindTypeFirst) return;

            double now = CACurrentMediaTime();

            // 1. Tự Động Bảo Quản Cá: eDialogType = 400 (FishingGetItem)
            if (g_config.autoPreserveFish) {
                void* fishDialog = p_FindTypeFirst(dialogSys, 400);
                if (fishDialog && (uintptr_t)fishDialog >= 0x100000000ULL) {
                    g_activeFishingGetItem = fishDialog;
                    if (s_lastFishDialog != fishDialog) {
                        s_lastFishDialog = fishDialog;
                        s_fishDialogOpenTime = now;
                    }
                    if (now - s_fishDialogOpenTime >= (double)g_config.autoPreserveDelay) {
                        if (!p_DialogFishingGetItem_OnClick_Close) {
                            p_DialogFishingGetItem_OnClick_Close = (DialogFishingGetItem_OnClick_Close_t)Memory::GetRealOffset(Offsets::Dialogs::DialogFishingGetItem_OnClick_Close);
                        }
                        if (p_DialogFishingGetItem_OnClick_Close) {
                            p_DialogFishingGetItem_OnClick_Close(fishDialog);
                            g_stats.fishPreservedCount++;
                            s_lastFishDialog = nullptr;
                            s_fishDialogOpenTime = now + 1.0; // Cooldown
                        }
                    }
                } else {
                    s_lastFishDialog = nullptr;
                }
            }

            // 2. Tự Động Đóng Hộp Thẻ: eDialogType = 96 (ResultGetItemView)
            if (g_config.autoCloseCardBox) {
                void* resultDialog = p_FindTypeFirst(dialogSys, 96);
                if (resultDialog && (uintptr_t)resultDialog >= 0x100000000ULL) {
                    g_activeResultItemView = resultDialog;
                    if (s_lastResultDialog != resultDialog) {
                        s_lastResultDialog = resultDialog;
                        s_resultDialogOpenTime = now;
                    }
                    if (now - s_resultDialogOpenTime >= (double)g_config.autoCloseDelay) {
                        if (!p_DialogResultGetItemView_CloseFromBack) {
                            p_DialogResultGetItemView_CloseFromBack = (DialogResultGetItemView_CloseFromBack_t)Memory::GetRealOffset(Offsets::Dialogs::DialogResultGetItemView_DialogCloseFromBack);
                        }
                        if (p_DialogResultGetItemView_CloseFromBack) {
                            p_DialogResultGetItemView_CloseFromBack(resultDialog);
                            g_stats.cardBoxesClosedCount++;
                            s_lastResultDialog = nullptr;
                            s_resultDialogOpenTime = now + 1.0;
                        }
                    }
                } else {
                    s_lastResultDialog = nullptr;
                }
            }

            // 3. Tự Động Đóng Hộp Quà: eDialogType = 21 (RewardPopup)
            if (g_config.autoCloseGift) {
                void* rewardDialog = p_FindTypeFirst(dialogSys, 21);
                if (rewardDialog && (uintptr_t)rewardDialog >= 0x100000000ULL) {
                    g_activeRewardPopup = rewardDialog;
                    if (s_lastRewardDialog != rewardDialog) {
                        s_lastRewardDialog = rewardDialog;
                        s_rewardDialogOpenTime = now;
                    }
                    if (now - s_rewardDialogOpenTime >= (double)g_config.autoCloseDelay) {
                        if (!p_DialogRewardPopup_DialogHide) {
                            p_DialogRewardPopup_DialogHide = (DialogRewardPopup_DialogHide_t)Memory::GetRealOffset(Offsets::Dialogs::DialogRewardPopup_DialogHide);
                        }
                        if (p_DialogRewardPopup_DialogHide) {
                            p_DialogRewardPopup_DialogHide(rewardDialog, false);
                            g_stats.giftsClosedCount++;
                            s_lastRewardDialog = nullptr;
                            s_rewardDialogOpenTime = now + 1.0;
                        }
                    }
                } else {
                    s_lastRewardDialog = nullptr;
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void EnsureHooksInstalled() {
        LOG_INFO("MainFeatures dynamic runtime bindings ready.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }
    void ResetStats() { g_stats = { 0, 0, 0 }; }

    void* GetActiveFishingGetItemDialog() { return g_activeFishingGetItem; }
    void* GetActiveRewardPopup() { return g_activeRewardPopup; }
    void* GetActiveResultItemView() { return g_activeResultItemView; }
}
