#import "FishingFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "Includes/IMGUI/imgui.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <sstream>

namespace FishingFeatures {

    static Config g_config = {
        false,  // autoFishingEnabled
        true,   // autoCastRod
        1.2f,   // castDelay (1.2s)
        true,   // autoHitBite
        0.05f,  // hitReactionDelay (0.05s)
        true,   // bigFishMinigameEnabled
        0.08f,  // stunTapInterval (80ms)
        true,   // keepFishShadow67
        false,  // fastCatch
        { true, true, true, true, true, true, true, true }, // All 7 shadows allowed by default
        false,  // enableIdFilter
        { false } // filterFishIds
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
        "Đang đợi người chơi..."
    };

    typedef void* (*get_Actor_t)();
    static get_Actor_t p_get_Actor = nullptr;

    typedef void* (*get_MyActorCharacter_t)(void* actorSys);
    static get_MyActorCharacter_t p_get_MyActorCharacter = nullptr;

    typedef void* (*get_ActorCharacterControl_t)(void* myChar);
    static get_ActorCharacterControl_t p_get_ActorCharacterControl = nullptr;

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
            case 0: return "Nghỉ (Chưa quăng)";
            case 1: return "Đang Quăng Cần";
            case 2: return "Đang Dò Cá";
            case 3: return "Cá Đã Thấy Mồi";
            case 4: return "Chờ Cá Cắn";
            case 5: return "Cá Cắn Câu (!)";
            case 6: return "Đang Giằng Co";
            case 7: return "Đã Câu Được Cá";
            case 8: return "Câu Thất Bại";
            case 9: return "Khoe Cá";
            case 10: return "Hoàn Thành";
            case 11: return "Quăng Hụt";
            case 12: return "Hụt Mồi";
            case 13: return "Cá Khổng Lồ: Vào Trận";
            case 14: return "Cá Khổng Lồ: Đồng Bộ";
            case 15: return "Cá Khổng Lồ: Bắt Đầu";
            case 16: return "Cá Khổng Lồ: Kéo (Pumpin)";
            case 17: return "Cá Khổng Lồ: Rê (Drag)";
            case 18: return "Cá Khổng Lồ: Giật (Tug)";
            case 19: return "Cá Khổng Lồ: Chiến Đấu";
            case 20: return "Cá Khổng Lồ: Bắt Thành Công";
            case 21: return "Cá Khổng Lồ: Đứt Dây";
            default: return "Đang Câu...";
        }
    }

    void* GetLocalPlayerControl() {
        if (!p_get_Actor) {
            p_get_Actor = (get_Actor_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Actor);
        }
        if (!p_get_Actor) return nullptr;

        void* actorSys = p_get_Actor();
        if (!actorSys || (uintptr_t)actorSys < 0x100000000ULL) return nullptr;

        if (!p_get_MyActorCharacter) {
            p_get_MyActorCharacter = (get_MyActorCharacter_t)Memory::GetRealOffset(0x37BE104);
        }
        if (!p_get_MyActorCharacter) return nullptr;

        void* myChar = p_get_MyActorCharacter(actorSys);
        if (!myChar || (uintptr_t)myChar < 0x100000000ULL) return nullptr;

        if (!p_get_ActorCharacterControl) {
            p_get_ActorCharacterControl = (get_ActorCharacterControl_t)Memory::GetRealOffset(0x381A17C);
        }
        if (!p_get_ActorCharacterControl) return nullptr;

        void* myControl = p_get_ActorCharacterControl(myChar);
        if (!myControl || (uintptr_t)myControl < 0x100000000ULL) return nullptr;

        return myControl;
    }

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        @try {
            void* player = GetLocalPlayerControl();
            if (!player) {
                g_status.activePlayerController = nullptr;
                g_status.lastStateName = "Đang vào map...";
                return;
            }

            g_status.activePlayerController = player;

            if (!p_get_HasFishingPole) {
                p_get_HasFishingPole = (get_HasFishingPole_t)Memory::GetRealOffset(Offsets::Fishing::get_HasFishingPole);
            }
            if (!p_get_FishingState) {
                p_get_FishingState = (get_FishingState_t)Memory::GetRealOffset(Offsets::Fishing::get_FishingState);
            }
            if (!p_OnClickFishing) {
                p_OnClickFishing = (OnClickFishing_t)Memory::GetRealOffset(Offsets::Fishing::OnClickFishing);
            }
            if (!p_FishingCancel) {
                p_FishingCancel = (FishingCancel_t)Memory::GetRealOffset(Offsets::Fishing::FishingCancel);
            }

            bool hasPole = (p_get_HasFishingPole && p_get_HasFishingPole(player));
            if (!hasPole) {
                g_status.lastStateName = "Chưa cầm cần câu";
                g_status.isFishingActive = false;
                return;
            }

            int currentState = p_get_FishingState ? p_get_FishingState(player) : 0;
            g_status.currentPlayerState = (GameTypes::eFishingState)currentState;
            g_status.lastStateName = GetFishingStateName(currentState);
            g_status.isFishingActive = (currentState > 0 && currentState != 10);

            // Safe toggle transition detection
            if (g_config.autoFishingEnabled && !s_wasAutoFishing) {
                s_waitingRecast = false;
                s_hasHitCurrentBite = false;
                s_needFilterCancel = false;
                s_lastState = -1;
            }
            s_wasAutoFishing = g_config.autoFishingEnabled;

            if (!g_config.autoFishingEnabled) return;

            double now = CACurrentMediaTime();

            if (currentState != s_lastState) {
                s_lastState = currentState;
                s_stateChangeTime = now;
                s_hasHitCurrentBite = false;
            }

            // Xử lý hủy quăng nếu dính bóng cá đã bị lọc bỏ
            if (s_needFilterCancel) {
                s_needFilterCancel = false;
                if (p_FishingCancel) {
                    p_FishingCancel(player);
                } else if (p_OnClickFishing) {
                    p_OnClickFishing(player);
                }
                return;
            }

            // 1. Nhận diện cá cắn câu (Dấu chấm than ! - State 5)
            if (currentState == 5) {
                if (!s_hasHitCurrentBite) {
                    double elapsed = now - s_stateChangeTime;
                    if (elapsed >= (double)g_config.hitReactionDelay) {
                        s_hasHitCurrentBite = true;
                        if (p_OnClickFishing) {
                            p_OnClickFishing(player);
                        }
                    }
                }
            }
            // 2. Minigame kéo cá thường (Fighting = 6) & Minigame Cá Khổng Lồ (Bóng 6, 7: States 13..25)
            // Chuẩn logic Cate: Tự động nhấp giật liên tục (Pumping & Reeling) để kéo cá vào bờ
            else if (currentState == 6) {
                g_status.isInMinigame = true;
                if (now - s_lastActionTime >= 0.15) {
                    s_lastActionTime = now;
                    if (p_OnClickFishing) {
                        p_OnClickFishing(player);
                    }
                }
            }
            else if (currentState == 16 || currentState == 18 || currentState == 19 || 
                     currentState == 22 || currentState == 23 || currentState == 24 || currentState == 25) {
                g_status.isInMinigame = true;
                // Nhấp giật theo nhịp chuẩn máy bay tự động kéo cá:
                // Stun (23, 24): Tốc độ siêu nhanh 80ms. Pumpin/Fighting (16, 19, 22): Tốc độ 110ms.
                double cadence = (currentState == 23 || currentState == 24) ? 0.08 : 0.11;
                if (now - s_lastActionTime >= cadence) {
                    s_lastActionTime = now;
                    if (p_OnClickFishing) {
                        p_OnClickFishing(player);
                    }
                }
            }
            else if (currentState == 17) {
                // BigFish_Drag: Cá đang kéo căng dây cực mạnh, nhấp giữ nhịp chậm 220ms để không đứt dây
                g_status.isInMinigame = true;
                if (now - s_lastActionTime >= 0.22) {
                    s_lastActionTime = now;
                    if (p_OnClickFishing) {
                        p_OnClickFishing(player);
                    }
                }
            }
            else if (currentState >= 13 && currentState <= 15) {
                g_status.isInMinigame = true;
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
                            p_OnClickFishing(player);
                        }
                    }
                } else if (g_config.autoCastRod && now - s_stateChangeTime >= (double)g_config.castDelay) {
                    // Quăng mẻ đầu tiên khi bật auto
                    s_waitingRecast = false;
                    s_stateChangeTime = now;
                    if (p_OnClickFishing) {
                        p_OnClickFishing(player);
                    }
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void Initialize() {
        for (size_t i = 0; i < k_fishTableCount; i++) {
            uint32_t fid = k_fishTable[i].id;
            if (fid < 25000) {
                g_config.filterFishIds[fid] = true;
            }
        }
        LOG_INFO("Fishing Subsystem Initialized with SystemHelper dynamic runtime binding and FishTable.");
    }

    Config& GetConfig() { return g_config; }
    Status GetStatus() { return g_status; }

    void ResetStats() {
        g_status.totalFishCaught = 0;
        g_status.bigFishCompleted = 0;
    }

    void TriggerCast() {
        void* player = GetLocalPlayerControl();
        if (player && p_OnClickFishing) {
            p_OnClickFishing(player);
        }
    }

    void TriggerReel() {
        void* player = GetLocalPlayerControl();
        if (player && p_OnClickFishing) {
            p_OnClickFishing(player);
        }
    }

    std::string GetSelectedFishIdsString() {
        std::string res;
        for (size_t i = 0; i < k_fishTableCount; i++) {
            uint32_t fid = k_fishTable[i].id;
            if (fid < 25000 && g_config.filterFishIds[fid]) {
                if (!res.empty()) res += ", ";
                res += std::to_string(fid);
            }
        }
        return res;
    }

    void CopySelectedFishIdsToClipboard() {
        std::string idsStr = GetSelectedFishIdsString();
        if (idsStr.empty()) return;
        NSString* nsStr = [NSString stringWithUTF8String:idsStr.c_str()];
        [UIPasteboard generalPasteboard].string = nsStr;
        ImGui::SetClipboardText(idsStr.c_str());
        LOG_INFO("Copied selected fish IDs to clipboard: " + idsStr);
    }

    void CopySingleFishIdToClipboard(uint32_t id) {
        std::string s = std::to_string(id);
        NSString* nsStr = [NSString stringWithUTF8String:s.c_str()];
        [UIPasteboard generalPasteboard].string = nsStr;
        ImGui::SetClipboardText(s.c_str());
        LOG_INFO("Copied fish ID to clipboard: " + s);
    }

    void SelectAllFishIds(bool select) {
        for (size_t i = 0; i < k_fishTableCount; i++) {
            uint32_t fid = k_fishTable[i].id;
            if (fid < 25000) {
                g_config.filterFishIds[fid] = select;
            }
        }
    }

    void SelectShadowFishIds(int shadow, bool select) {
        for (size_t i = 0; i < k_fishTableCount; i++) {
            if (k_fishTable[i].shadow == shadow) {
                uint32_t fid = k_fishTable[i].id;
                if (fid < 25000) {
                    g_config.filterFishIds[fid] = select;
                }
            }
        }
    }
}
