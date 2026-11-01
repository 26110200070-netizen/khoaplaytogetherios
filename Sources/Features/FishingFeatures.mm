#import "FishingFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import <QuartzCore/QuartzCore.h>

namespace FishingFeatures {

    static Config g_config = {
        false,  // autoFishingEnabled (Merged normal + big fish)
        true,   // autoCastRod
        1.2f,   // castDelay (1.2s)
        true,   // autoHitBite
        0.05f,  // hitReactionDelay (0.05s)
        true,   // bigFishMinigameEnabled
        0.08f,  // stunTapInterval (80ms)
        true,   // keepFishShadow67
        false,  // fastCatch
        { true, true, true, true, true, true, true, true } // All 7 shadows allowed by default
    };

    static Status g_status = {
        GameTypes::FloatState::None,
        GameTypes::eFishingState::None,
        nullptr,
        nullptr,
        0,
        0,
        false,
        false,
        "None"
    };

    typedef void (*OnClickFishing_t)(void* this_ptr);
    static OnClickFishing_t p_OnClickFishing = nullptr;

    typedef void (*FishingCancel_t)(void* this_ptr);
    static FishingCancel_t p_FishingCancel = nullptr;

    typedef int (*get_FishingState_t)(void* this_ptr);
    static get_FishingState_t p_get_FishingState = nullptr;

    typedef bool (*get_HasFishingPole_t)(void* this_ptr);
    static get_HasFishingPole_t p_get_HasFishingPole = nullptr;

    typedef bool (*get_IsFishing_t)(void* this_ptr);
    static get_IsFishing_t p_get_IsFishing = nullptr;

    static int s_lastState = -1;
    static double s_stateChangeTime = 0.0;
    static double s_lastActionTime = 0.0;
    static double s_finishTime = 0.0;
    static bool s_hasHitCurrentBite = false;
    static bool s_waitingRecast = false;
    static bool s_needFilterCancel = false;
    static bool s_wasAutoFishing = false;

    static const char* GetFishingStateName(int state) {
        switch (state) {
            case 0: return "None";
            case 1: return "Casting";
            case 2: return "Search";
            case 3: return "SearchResult";
            case 4: return "Idle";
            case 5: return "Hit (!)";
            case 6: return "Fighting";
            case 7: return "Catch";
            case 8: return "Fail";
            case 9: return "Boast";
            case 10: return "Finish";
            case 11: return "CastingFail";
            case 12: return "Miss";
            case 13: return "BigFish_RaidEnter";
            case 14: return "BigFish_RaidSync";
            case 15: return "BigFish_Begin";
            case 16: return "BigFish_Pumpin";
            case 17: return "BigFish_Drag";
            case 18: return "BigFish_Tug";
            case 19: return "BigFish_Fighting";
            case 20: return "BigFish_Catch";
            case 21: return "BigFish_Miss";
            default: return "Unknown";
        }
    }

    // --------------------------------------------------------------------------
    // Hook: ActorDefaultControlPlayer.OnLateUpdate
    // Runs on Unity engine thread every frame for the local player
    // --------------------------------------------------------------------------
    void (*orig_OnLateUpdate)(void* this_ptr) = nullptr;
    void hook_OnLateUpdate(void* this_ptr) {
        if (orig_OnLateUpdate) {
            orig_OnLateUpdate(this_ptr);
        }

        if (!this_ptr || (uintptr_t)this_ptr < 0x100000000ULL) return;
        g_status.activePlayerController = this_ptr;

        @try {
            // Safe toggle transition detection
            if (g_config.autoFishingEnabled && !s_wasAutoFishing) {
                s_waitingRecast = false;
                s_hasHitCurrentBite = false;
                s_needFilterCancel = false;
                s_lastState = -1;
            }
            s_wasAutoFishing = g_config.autoFishingEnabled;

            if (!g_config.autoFishingEnabled || !p_get_FishingState) return;

            // Ensure player has a fishing pole equipped before executing any action
            if (p_get_HasFishingPole && !p_get_HasFishingPole(this_ptr)) {
                return;
            }

            // Handle shadow cancellation safely on the player thread
            if (s_needFilterCancel) {
                s_needFilterCancel = false;
                if (p_FishingCancel) {
                    p_FishingCancel(this_ptr);
                } else if (p_OnClickFishing) {
                    p_OnClickFishing(this_ptr);
                }
                return;
            }

            double now = CACurrentMediaTime();
            int currentState = p_get_FishingState(this_ptr);

            if (currentState != s_lastState) {
                s_lastState = currentState;
                s_stateChangeTime = now;
                s_hasHitCurrentBite = false;
                g_status.currentPlayerState = (GameTypes::eFishingState)currentState;
                g_status.lastStateName = GetFishingStateName(currentState);
            }

            // 1. Nhận diện cắn câu (Dấu chấm than ! - State 5)
            if (currentState == 5) {
                if (!s_hasHitCurrentBite) {
                    double elapsed = now - s_stateChangeTime;
                    if (elapsed >= (double)g_config.hitReactionDelay) {
                        s_hasHitCurrentBite = true;
                        if (p_OnClickFishing) {
                            p_OnClickFishing(this_ptr);
                        }
                    }
                }
            }
            // 2. Tự động giải Minigame cá khổng lồ / kéo cá (States 16, 17, 18, 19)
            else if (currentState == 16 || currentState == 17 || currentState == 18 || currentState == 19) {
                g_status.isInMinigame = true;
                if (now - s_lastActionTime >= (double)g_config.stunTapInterval) {
                    s_lastActionTime = now;
                    if (p_OnClickFishing) {
                        p_OnClickFishing(this_ptr);
                    }
                }
            }
            // 3. Bắt được cá thành công (State 7 hoặc 20)
            else if (currentState == 7 || currentState == 20) {
                if (!s_waitingRecast) {
                    s_waitingRecast = true;
                    s_finishTime = now;
                    g_status.isInMinigame = false;
                    g_status.totalFishCaught++;
                    if (currentState == 20) {
                        g_status.bigFishCompleted++;
                    }
                }
            }
            // 4. Cá hụt / đứt dây (State 8, 12, 21)
            else if (currentState == 8 || currentState == 12 || currentState == 21) {
                if (!s_waitingRecast) {
                    s_waitingRecast = true;
                    s_finishTime = now;
                    g_status.isInMinigame = false;
                }
            }
            // 5. Trạng thái nghỉ / hoàn thành -> Quăng cần lại tự động
            else if (currentState == 0 || currentState == 10) {
                if (s_waitingRecast) {
                    double elapsedSinceFinish = now - s_finishTime;
                    if (elapsedSinceFinish >= (double)g_config.castDelay) {
                        s_waitingRecast = false;
                        if (g_config.autoCastRod && p_OnClickFishing) {
                            p_OnClickFishing(this_ptr);
                        }
                    }
                }
            }
        } @catch (NSException *ex) {
            // Suppress exceptions to guarantee game stability
        }
    }

    // --------------------------------------------------------------------------
    // Hook: FishShadowController.InitilaizeFish
    // Lọc bóng cá: Nếu bóng cá bị bỏ chọn, giật cần về ngay lập tức để quăng lại
    // --------------------------------------------------------------------------
    void (*orig_InitilaizeFish)(void* this_ptr, void* floatControl, uint32_t level, void* waterCol, bool noDelay, bool isBigFish) = nullptr;
    void hook_InitilaizeFish(void* this_ptr, void* floatControl, uint32_t level, void* waterCol, bool noDelay, bool isBigFish) {
        if (orig_InitilaizeFish) {
            orig_InitilaizeFish(this_ptr, floatControl, level, waterCol, noDelay, isBigFish);
        }

        @try {
            if (!g_config.autoFishingEnabled) return;
            if (!g_status.activePlayerController) return;

            // Verify that this fish actually belongs to OUR active rod float (offset 0x408)
            void* myFloat = *(void**)((uintptr_t)g_status.activePlayerController + 0x408);
            if (myFloat && floatControl && myFloat != floatControl) {
                return; // Belongs to another player's rod, ignore!
            }

            if (level >= 1 && level <= 7) {
                if (!g_config.filterShadow[level]) {
                    // Bóng cá bị lọc bỏ -> gắn cờ cancel an toàn
                    s_needFilterCancel = true;
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    // --------------------------------------------------------------------------
    // Safe Subsystem Initialization
    // --------------------------------------------------------------------------
    static bool s_hooksInstalled = false;

    void InstallHooks() {
        if (s_hooksInstalled) return;
        s_hooksInstalled = true;

        LOG_INFO("Installing Fishing Subsystem Hooks...");

        p_OnClickFishing     = (OnClickFishing_t)Memory::GetRealOffset(Offsets::Fishing::OnClickFishing);
        p_FishingCancel      = (FishingCancel_t)Memory::GetRealOffset(Offsets::Fishing::FishingCancel);
        p_get_FishingState   = (get_FishingState_t)Memory::GetRealOffset(Offsets::Fishing::get_FishingState);
        p_get_HasFishingPole = (get_HasFishingPole_t)Memory::GetRealOffset(Offsets::Fishing::get_HasFishingPole);
        p_get_IsFishing      = (get_IsFishing_t)Memory::GetRealOffset(Offsets::Fishing::get_IsFishing);

        // 1. Hook ActorDefaultControlPlayer.OnLateUpdate
        uintptr_t lateUpdateAddr = Memory::GetRealOffset(Offsets::Fishing::OnLateUpdate);
        if (lateUpdateAddr >= 0x100000000ULL) {
            Memory::InstallHook((void*)lateUpdateAddr,
                (void*)hook_OnLateUpdate,
                (void**)&orig_OnLateUpdate,
                "ActorDefaultControlPlayer.OnLateUpdate");
        }

        // 2. Hook FishShadowController.InitilaizeFish (RVA 0x2D22FE8)
        uintptr_t initFishAddr = Memory::GetRealOffset(0x2D22FE8);
        if (initFishAddr >= 0x100000000ULL) {
            Memory::InstallHook((void*)initFishAddr,
                (void*)hook_InitilaizeFish,
                (void**)&orig_InitilaizeFish,
                "FishShadowController.InitilaizeFish");
        }

        LOG_SUCCESS("Fishing Subsystem Hooks Installed Successfully!");
    }

    void Initialize() {
        InstallHooks();
    }

    Config& GetConfig() { return g_config; }
    Status GetStatus() { return g_status; }

    void ResetStats() {
        g_status.totalFishCaught = 0;
        g_status.bigFishCompleted = 0;
    }

    void TriggerCast() {
        if (g_status.activePlayerController && p_OnClickFishing) {
            p_OnClickFishing(g_status.activePlayerController);
        }
    }

    void TriggerReel() {
        if (g_status.activePlayerController && p_OnClickFishing) {
            p_OnClickFishing(g_status.activePlayerController);
        }
    }
}
