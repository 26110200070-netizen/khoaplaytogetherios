#import "MainFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import <Foundation/Foundation.h>

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

    typedef void (*DialogFishingGetItem_OnClick_Close_t)(void* this_ptr);
    static DialogFishingGetItem_OnClick_Close_t p_DialogFishingGetItem_OnClick_Close = nullptr;

    typedef void (*DialogRewardPopup_OnClickYes_t)(void* this_ptr);
    static DialogRewardPopup_OnClickYes_t p_DialogRewardPopup_OnClickYes = nullptr;

    typedef void (*DialogResultGetItemView_CloseFromBack_t)(void* this_ptr);
    static DialogResultGetItemView_CloseFromBack_t p_DialogResultGetItemView_CloseFromBack = nullptr;

    typedef void (*DialogResultGetItemList_CloseFromBack_t)(void* this_ptr);
    static DialogResultGetItemList_CloseFromBack_t p_DialogResultGetItemList_CloseFromBack = nullptr;

    // --------------------------------------------------------------------------
    // Hooks: DialogFishingGetItem (Auto Bảo quản)
    // --------------------------------------------------------------------------
    void (*orig_DialogFishingGetItem_DialogShow)(void* this_ptr) = nullptr;
    void hook_DialogFishingGetItem_DialogShow(void* this_ptr) {
        if (orig_DialogFishingGetItem_DialogShow) {
            orig_DialogFishingGetItem_DialogShow(this_ptr);
        }
        g_activeFishingGetItem = this_ptr;

        if (g_config.autoPreserveFish && p_DialogFishingGetItem_OnClick_Close && this_ptr) {
            float delay = g_config.autoPreserveDelay;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (p_DialogFishingGetItem_OnClick_Close && this_ptr) {
                    p_DialogFishingGetItem_OnClick_Close(this_ptr);
                    g_stats.fishPreservedCount++;
                }
            });
        }
    }

    // --------------------------------------------------------------------------
    // Hooks: DialogRewardPopup (Đóng quà)
    // --------------------------------------------------------------------------
    void (*orig_DialogRewardPopup_DialogShow)(void* this_ptr) = nullptr;
    void hook_DialogRewardPopup_DialogShow(void* this_ptr) {
        if (orig_DialogRewardPopup_DialogShow) {
            orig_DialogRewardPopup_DialogShow(this_ptr);
        }
        g_activeRewardPopup = this_ptr;

        if (g_config.autoCloseGift && p_DialogRewardPopup_OnClickYes && this_ptr) {
            float delay = g_config.autoCloseDelay;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (p_DialogRewardPopup_OnClickYes && this_ptr) {
                    p_DialogRewardPopup_OnClickYes(this_ptr);
                    g_stats.giftsClosedCount++;
                }
            });
        }
    }

    // --------------------------------------------------------------------------
    // Hooks: DialogResultGetItemView & DialogResultGetItemList (Đóng Hộp Thẻ / Gacha)
    // --------------------------------------------------------------------------
    void (*orig_DialogResultGetItemView_DialogShow)(void* this_ptr) = nullptr;
    void hook_DialogResultGetItemView_DialogShow(void* this_ptr) {
        if (orig_DialogResultGetItemView_DialogShow) {
            orig_DialogResultGetItemView_DialogShow(this_ptr);
        }
        g_activeResultItemView = this_ptr;

        if (g_config.autoCloseCardBox && p_DialogResultGetItemView_CloseFromBack && this_ptr) {
            float delay = g_config.autoCloseDelay;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (p_DialogResultGetItemView_CloseFromBack && this_ptr) {
                    p_DialogResultGetItemView_CloseFromBack(this_ptr);
                    g_stats.cardBoxesClosedCount++;
                }
            });
        }
    }

    void (*orig_DialogResultGetItemList_DialogShow)(void* this_ptr) = nullptr;
    void hook_DialogResultGetItemList_DialogShow(void* this_ptr) {
        if (orig_DialogResultGetItemList_DialogShow) {
            orig_DialogResultGetItemList_DialogShow(this_ptr);
        }
        g_activeResultItemList = this_ptr;

        if (g_config.autoCloseCardBox && p_DialogResultGetItemList_CloseFromBack && this_ptr) {
            float delay = g_config.autoCloseDelay;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (p_DialogResultGetItemList_CloseFromBack && this_ptr) {
                    p_DialogResultGetItemList_CloseFromBack(this_ptr);
                    g_stats.cardBoxesClosedCount++;
                }
            });
        }
    }

    // --------------------------------------------------------------------------
    // Initialization: Hook all dialogs safely ONCE at startup
    // --------------------------------------------------------------------------
    static bool s_mainHooksInstalled = false;

    void EnsureHooksInstalled() {
        if (s_mainHooksInstalled) return;
        s_mainHooksInstalled = true;

        LOG_INFO("Installing MainFeatures dialog hooks...");

        p_DialogFishingGetItem_OnClick_Close = (DialogFishingGetItem_OnClick_Close_t)Memory::GetRealOffset(Offsets::Dialogs::DialogFishingGetItem_OnClick_Close);
        p_DialogRewardPopup_OnClickYes = (DialogRewardPopup_OnClickYes_t)Memory::GetRealOffset(Offsets::Dialogs::DialogRewardPopup_OnClickYes);
        p_DialogResultGetItemView_CloseFromBack = (DialogResultGetItemView_CloseFromBack_t)Memory::GetRealOffset(Offsets::Dialogs::DialogResultGetItemView_DialogCloseFromBack);
        p_DialogResultGetItemList_CloseFromBack = (DialogResultGetItemList_CloseFromBack_t)Memory::GetRealOffset(Offsets::Dialogs::DialogResultGetItemList_DialogCloseFromBack);

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Dialogs::DialogFishingGetItem_DialogShow),
                            (void*)hook_DialogFishingGetItem_DialogShow,
                            (void**)&orig_DialogFishingGetItem_DialogShow,
                            "DialogFishingGetItem.DialogShow");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Dialogs::DialogRewardPopup_DialogShow),
                            (void*)hook_DialogRewardPopup_DialogShow,
                            (void**)&orig_DialogRewardPopup_DialogShow,
                            "DialogRewardPopup.DialogShow");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Dialogs::DialogResultGetItemView_DialogShow),
                            (void*)hook_DialogResultGetItemView_DialogShow,
                            (void**)&orig_DialogResultGetItemView_DialogShow,
                            "DialogResultGetItemView.DialogShow");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Dialogs::DialogResultGetItemList_DialogShow),
                            (void*)hook_DialogResultGetItemList_DialogShow,
                            (void**)&orig_DialogResultGetItemList_DialogShow,
                            "DialogResultGetItemList.DialogShow");

        LOG_SUCCESS("MainFeatures: Dialog hooks ACTIVE.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() {
        return g_config;
    }

    Stats GetStats() {
        return g_stats;
    }

    void ResetStats() {
        g_stats.fishPreservedCount = 0;
        g_stats.giftsClosedCount = 0;
        g_stats.cardBoxesClosedCount = 0;
    }

    void* GetActiveFishingGetItemDialog() { return g_activeFishingGetItem; }
    void* GetActiveRewardPopup() { return g_activeRewardPopup; }
    void* GetActiveResultItemView() { return g_activeResultItemView; }
}
