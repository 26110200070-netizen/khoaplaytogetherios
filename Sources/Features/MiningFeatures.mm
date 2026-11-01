#import "MiningFeatures.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"
#import "PlayerFeatures.h"
#import <QuartzCore/QuartzCore.h>
#import <cmath>

namespace MiningFeatures {

    static Config g_config = {
        false, // autoMineRocks
        false, // autoChangeMapMine
        false, // autoPickupItems
        false, // autoChangeMapPickup
        false, // autoExcavate
        0.3f,  // excavateDelay
        false, // teleAllStones
        false, // teleSmallStones
        false, // teleMediumStones
        false  // teleLargeStones
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
    static double s_lastTeleTime = 0.0;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnClickPickax = (OnClickPickax_t)Memory::GetRealOffset(Offsets::Extended::OnClickPickax);
        p_OnClickExcavate = (OnClickExcavate_t)Memory::GetRealOffset(Offsets::Extended::OnClickExcavate);
        p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
        p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);

        LOG_INFO("MiningFeatures runtime pointers initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        @try {
            void* player = FishingFeatures::GetLocalPlayerControl();
            if (!player || (uintptr_t)player < 0x100000000ULL) return;

            if (!p_OnClickPickax) {
                p_OnClickPickax = (OnClickPickax_t)Memory::GetRealOffset(Offsets::Extended::OnClickPickax);
            }
            if (!p_OnClickExcavate) {
                p_OnClickExcavate = (OnClickExcavate_t)Memory::GetRealOffset(Offsets::Extended::OnClickExcavate);
            }
            if (!p_get_Collect) {
                p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
            }
            if (!p_MapObject_get_DetectTargetPos) {
                p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);
            }

            double now = CACurrentMediaTime();

            // 1. Auto Đập Đá & Tele Đá (Auto Mine Rocks)
            if (g_config.autoMineRocks && p_OnClickPickax) {
                // Boost Pickax reach radius in CollectSystem if available
                if (p_get_Collect) {
                    void* collectSys = p_get_Collect();
                    if (collectSys && (uintptr_t)collectSys >= 0x100000000ULL) {
                        float* p_rad = (float*)((uintptr_t)collectSys + 0x1B8);
                        if (*p_rad < 50.0f) {
                            *p_rad = 50.0f; // Reach radius 50m
                        }

                        // Teleport to nearest rock if tele rocks enabled
                        bool shouldTele = g_config.teleAllStones || g_config.teleSmallStones || g_config.teleMediumStones || g_config.teleLargeStones;
                        if (shouldTele && (now - s_lastTeleTime >= 1.2)) {
                            void* mapObjList = *(void**)((uintptr_t)collectSys + 0x180);
                            if (mapObjList && (uintptr_t)mapObjList >= 0x100000000ULL) {
                                void* itemsArray = *(void**)((uintptr_t)mapObjList + 0x10);
                                int32_t size = *(int32_t*)((uintptr_t)mapObjList + 0x18);
                                if (itemsArray && size > 0 && size < 500) {
                                    for (int32_t i = 0; i < size; i++) {
                                        void* rockObj = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                                        if (!rockObj || (uintptr_t)rockObj < 0x100000000ULL) continue;

                                        // ObjectState state at offset 0x18 (0: None, 1: Active, 2: Destroyed)
                                        int32_t state = *(int32_t*)((uintptr_t)rockObj + 0x18);
                                        if (state == 2) continue; // Already destroyed

                                        if (p_MapObject_get_DetectTargetPos) {
                                            GameTypes::Vector3 rpos = p_MapObject_get_DetectTargetPos(rockObj);
                                            if (fabsf(rpos.x) > 0.01f || fabsf(rpos.z) > 0.01f) {
                                                PlayerFeatures::Teleport(rpos.x, rpos.y + 0.3f, rpos.z);
                                                s_lastTeleTime = now;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if (now - s_lastMineHitTime >= 0.35) {
                    s_lastMineHitTime = now;
                    p_OnClickPickax(player);
                    g_stats.rocksMined++;
                }
            }

            // 2. Auto Khai Quật / Đào Kho Báu (Excavate)
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
