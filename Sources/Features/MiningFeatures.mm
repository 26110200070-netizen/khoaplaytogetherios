#import "MiningFeatures.h"
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

namespace MiningFeatures {

    static Config g_config = {
        false, // autoMineRocks
        false, // autoChangeMap
        true,  // cycleMapPlaza
        true,  // cycleMapCamping
        true,  // cycleMapResort
        true,  // cycleMapDowntown
        true,  // teleAllStones
        false, // teleSmallStones
        false, // teleMediumStones
        false, // teleLargeStones
        false, // autoExcavate
        0.3f   // excavateDelay
    };

    static Stats g_stats = { 0, 0 };

    typedef bool (*OnClickPickax_t)(void* this_ptr);
    static OnClickPickax_t p_OnClickPickax = nullptr;

    typedef bool (*OnClickExcavate_t)(void* this_ptr);
    static OnClickExcavate_t p_OnClickExcavate = nullptr;

    typedef void* (*get_Collect_t)();
    static get_Collect_t p_get_Collect = nullptr;

    typedef GameTypes::Vector3 (*MapObject_get_DetectTargetPos_t)(void* obj);
    static MapObject_get_DetectTargetPos_t p_MapObject_get_DetectTargetPos = nullptr;

    static double s_lastMineHitTime = 0.0;
    static double s_lastExcavateTime = 0.0;
    static double s_lastMapChangeTime = 0.0;
    static size_t s_currentCycleIndex = 0;
    static void* s_currentTargetRock = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnClickPickax = (OnClickPickax_t)Memory::GetRealOffset(Offsets::Extended::OnClickPickax);
        p_OnClickExcavate = (OnClickExcavate_t)Memory::GetRealOffset(Offsets::Extended::OnClickExcavate);
        p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
        p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);

        LOG_INFO("MiningFeatures initialized.");
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

            if (!p_OnClickPickax) p_OnClickPickax = (OnClickPickax_t)Memory::GetRealOffset(Offsets::Extended::OnClickPickax);
            if (!p_OnClickExcavate) p_OnClickExcavate = (OnClickExcavate_t)Memory::GetRealOffset(Offsets::Extended::OnClickExcavate);
            if (!p_get_Collect) p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
            if (!p_MapObject_get_DetectTargetPos) p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);

            if (!p_get_Collect) return;
            void* collectSys = p_get_Collect();
            if (!collectSys || (uintptr_t)collectSys < 0x100000000ULL) return;

            // Mở rộng bán kính gõ cuốc của CollectSystem lên 50m
            float* p_rad = (float*)((uintptr_t)collectSys + 0x1B8);
            if (*p_rad < 50.0f) *p_rad = 50.0f;

            // Quét danh sách quặng đá
            void* mapObjList = *(void**)((uintptr_t)collectSys + 0x180);
            std::vector<void*> validRocks;
            if (mapObjList && (uintptr_t)mapObjList >= 0x100000000ULL) {
                void* itemsArray = *(void**)((uintptr_t)mapObjList + 0x10);
                int32_t size = *(int32_t*)((uintptr_t)mapObjList + 0x18);
                if (itemsArray && size > 0 && size < 500) {
                    for (int32_t i = 0; i < size; i++) {
                        void* rockObj = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                        if (!rockObj || (uintptr_t)rockObj < 0x100000000ULL) continue;

                        int32_t state = *(int32_t*)((uintptr_t)rockObj + 0x18);
                        if (state == 2) continue; // Đã vỡ

                        validRocks.push_back(rockObj);
                    }
                }
            }
            g_stats.rocksInMap = (uint32_t)validRocks.size();

            double now = CACurrentMediaTime();

            // 1. Tự Động Đổi Map Khi Hết Đá
            if (g_config.autoChangeMap && validRocks.empty()) {
                if (now - s_lastMapChangeTime >= 4.0) {
                    s_lastMapChangeTime = now;
                    std::vector<uint32_t> cycle = GetEnabledMapList();
                    if (!cycle.empty()) {
                        s_currentCycleIndex = (s_currentCycleIndex + 1) % cycle.size();
                        uint32_t nextMap = cycle[s_currentCycleIndex];
                        MapFeatures::TeleportToMap(nextMap);
                        s_currentTargetRock = nullptr;
                    }
                }
                return;
            }

            // 2. Logic Auto Đập Đá: Tự động tele đến đá rồi đập
            if (g_config.autoMineRocks && !validRocks.empty() && p_OnClickPickax) {
                // Kiểm tra xem mục tiêu hiện tại còn hợp lệ không
                bool targetValid = false;
                if (s_currentTargetRock) {
                    int32_t targetState = *(int32_t*)((uintptr_t)s_currentTargetRock + 0x18);
                    if (targetState != 2) {
                        for (void* r : validRocks) {
                            if (r == s_currentTargetRock) {
                                targetValid = true;
                                break;
                            }
                        }
                    }
                }

                // Nếu đá vỡ hoặc chưa có mục tiêu, tele tới viên đá mới
                if (!targetValid) {
                    if (s_currentTargetRock) {
                        g_stats.rocksMined++;
                    }
                    s_currentTargetRock = validRocks[0];
                    if (s_currentTargetRock && p_MapObject_get_DetectTargetPos) {
                        GameTypes::Vector3 rpos = p_MapObject_get_DetectTargetPos(s_currentTargetRock);
                        if (fabsf(rpos.x) > 0.01f || fabsf(rpos.z) > 0.01f) {
                            PlayerFeatures::Teleport(rpos.x, rpos.y + 0.2f, rpos.z);
                        }
                    }
                }

                // Gõ cuốc liên tục
                if (now - s_lastMineHitTime >= 0.35) {
                    s_lastMineHitTime = now;
                    p_OnClickPickax(player);
                }
            }

            // 3. Auto Khai Quật / Đào Kho Báu
            if (g_config.autoExcavate && p_OnClickExcavate) {
                double delay = g_config.excavateDelay > 0.1f ? (double)g_config.excavateDelay : 0.3;
                if (now - s_lastExcavateTime >= delay) {
                    s_lastExcavateTime = now;
                    p_OnClickExcavate(player);
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void TriggerPickaxHit() {
        void* player = FishingFeatures::GetLocalPlayerControl();
        if (player && p_OnClickPickax) {
            p_OnClickPickax(player);
            g_stats.rocksMined++;
        }
    }

    void TriggerExcavate() {
        void* player = FishingFeatures::GetLocalPlayerControl();
        if (player && p_OnClickExcavate) {
            p_OnClickExcavate(player);
        }
    }
}
