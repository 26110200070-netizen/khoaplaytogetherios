#import "InsectFeatures.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"
#import "PlayerFeatures.h"
#import "MapFeatures.h"
#import <QuartzCore/QuartzCore.h>
#import <vector>
#import <cmath>

namespace InsectFeatures {

    static Config g_config = {
        false, // autoCatchInsect
        false, // autoChangeMap
        true,  // cycleMapPlaza
        true,  // cycleMapCamping
        true,  // cycleMapResort
        true,  // cycleMapDowntown
        true   // showInfoPopup
    };

    static Stats g_stats = { 0, 0, 0, 100 };

    enum class CatchState {
        Idle,
        TeleportToInsect,
        Waiting2Seconds,
        SwingNet,
        Cooldown
    };

    static CatchState s_state = CatchState::Idle;
    static double s_teleportTime = 0.0;
    static double s_actionTime = 0.0;
    static double s_lastMapChangeTime = 0.0;
    static size_t s_currentCycleIndex = 0;
    static void* s_currentTargetControl = nullptr;

    typedef bool (*OnPressInsectNet_t)(void* this_ptr, bool isPress);
    static OnPressInsectNet_t p_OnPressInsectNet = nullptr;

    typedef void* (*get_Insect_t)();
    static get_Insect_t p_get_Insect = nullptr;

    typedef void* (*get_LiveInsectList_t)(void* this_ptr);
    static get_LiveInsectList_t p_get_LiveInsectList = nullptr;

    typedef GameTypes::Vector3 (*Insect_get_DetectTargetPos_t)(void* control);
    static Insect_get_DetectTargetPos_t p_Insect_get_DetectTargetPos = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnPressInsectNet = (OnPressInsectNet_t)Memory::GetRealOffset(Offsets::Extended::OnPressInsectNet);
        p_get_Insect = (get_Insect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Insect);
        p_get_LiveInsectList = (get_LiveInsectList_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_LiveInsectList);
        p_Insect_get_DetectTargetPos = (Insect_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_DetectTargetPos);

        LOG_INFO("InsectFeatures initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    static std::vector<uint32_t> GetEnabledMapList() {
        std::vector<uint32_t> maps;
        if (g_config.cycleMapPlaza) maps.push_back(1001);
        if (g_config.cycleMapCamping) maps.push_back(1201);
        if (g_config.cycleMapResort) maps.push_back(1301);
        if (g_config.cycleMapDowntown) maps.push_back(1502);
        return maps;
    }

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        @try {
            void* player = FishingFeatures::GetLocalPlayerControl();
            if (!player || (uintptr_t)player < 0x100000000ULL) return;

            if (!p_OnPressInsectNet) p_OnPressInsectNet = (OnPressInsectNet_t)Memory::GetRealOffset(Offsets::Extended::OnPressInsectNet);
            if (!p_get_Insect) p_get_Insect = (get_Insect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Insect);
            if (!p_get_LiveInsectList) p_get_LiveInsectList = (get_LiveInsectList_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_LiveInsectList);
            if (!p_Insect_get_DetectTargetPos) p_Insect_get_DetectTargetPos = (Insect_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_DetectTargetPos);

            if (!p_get_Insect || !p_get_LiveInsectList) return;
            void* insectSys = p_get_Insect();
            if (!insectSys || (uintptr_t)insectSys < 0x100000000ULL) return;

            void* liveList = p_get_LiveInsectList(insectSys);
            if (!liveList || (uintptr_t)liveList < 0x100000000ULL) return;

            void* itemsArray = *(void**)((uintptr_t)liveList + 0x10);
            int32_t size = *(int32_t*)((uintptr_t)liveList + 0x18);

            // 1. Quét và đếm số bọ còn sống trong map
            std::vector<void*> validInsects;
            if (itemsArray && size > 0 && size < 500) {
                for (int32_t i = 0; i < size; i++) {
                    void* insectEntry = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                    if (!insectEntry || (uintptr_t)insectEntry < 0x100000000ULL) continue;

                    void* control = *(void**)((uintptr_t)insectEntry + 0x20);
                    if (!control || (uintptr_t)control < 0x100000000ULL) continue;

                    validInsects.push_back(control);
                }
            }
            g_stats.insectsInMap = (uint32_t)validInsects.size();

            double now = CACurrentMediaTime();

            // 2. Tự Động Đổi Map Khi Hết Bọ (Xoay vòng các map đã chọn)
            if (g_config.autoChangeMap && validInsects.empty()) {
                if (now - s_lastMapChangeTime >= 4.0) {
                    s_lastMapChangeTime = now;
                    std::vector<uint32_t> cycle = GetEnabledMapList();
                    if (!cycle.empty()) {
                        s_currentCycleIndex = (s_currentCycleIndex + 1) % cycle.size();
                        uint32_t nextMap = cycle[s_currentCycleIndex];
                        MapFeatures::TeleportToMap(nextMap);
                        s_state = CatchState::Idle;
                    }
                }
                return;
            }

            if (!g_config.autoCatchInsect || validInsects.empty()) {
                s_state = CatchState::Idle;
                return;
            }

            // 3. Logic Tự Động Bắt Bọ Chuẩn Cate:
            // Tele tới bọ -> Đợi đúng 2s -> Vung vợt xuống là tự động dính -> Chuyển con tiếp theo
            switch (s_state) {
                case CatchState::Idle:
                case CatchState::TeleportToInsect: {
                    s_currentTargetControl = validInsects[0];
                    if (s_currentTargetControl && p_Insect_get_DetectTargetPos) {
                        GameTypes::Vector3 ipos = p_Insect_get_DetectTargetPos(s_currentTargetControl);
                        if (fabsf(ipos.x) > 0.01f || fabsf(ipos.z) > 0.01f) {
                            // Teleport trực tiếp tới vị trí bọ
                            PlayerFeatures::Teleport(ipos.x, ipos.y + 0.1f, ipos.z);
                            // Nhấn giữ vợt chuẩn bị bắt
                            if (p_OnPressInsectNet) {
                                p_OnPressInsectNet(player, true);
                            }
                            s_teleportTime = now;
                            s_state = CatchState::Waiting2Seconds;
                        }
                    }
                    break;
                }

                case CatchState::Waiting2Seconds: {
                    // Đợi đúng 2 giây theo yêu cầu
                    if (now - s_teleportTime >= 2.0) {
                        s_state = CatchState::SwingNet;
                    }
                    break;
                }

                case CatchState::SwingNet: {
                    // Thả vợt đập xuống
                    if (p_OnPressInsectNet) {
                        p_OnPressInsectNet(player, false);
                    }
                    g_stats.insectsCaught++;
                    g_stats.backpackCount++;
                    s_actionTime = now;
                    s_state = CatchState::Cooldown;
                    break;
                }

                case CatchState::Cooldown: {
                    // Nghỉ 0.5s sau khi vung vợt để game xử lý nhận bọ
                    if (now - s_actionTime >= 0.5) {
                        s_state = CatchState::TeleportToInsect;
                    }
                    break;
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void TriggerNetSwing() {
        void* player = FishingFeatures::GetLocalPlayerControl();
        if (player && p_OnPressInsectNet) {
            p_OnPressInsectNet(player, true);
            p_OnPressInsectNet(player, false);
            g_stats.insectsCaught++;
        }
    }
}
